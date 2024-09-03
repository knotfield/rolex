# Rolex

[![Hex.pm](https://img.shields.io/hexpm/v/rolex.svg)](https://hex.pm/packages/rolex) [![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/rolex/)

Rolex is a role management library for Elixir apps.

Goals:

- role management via grant, deny, and revoke
- a self-contained solution that doesn't invade the data model
- scoping of Ecto queries according to role requirements
- role requirement checks in memory using a list of permissions
- simple and consistent ergonomics throughout

Rolex is only meant to supply **part** of a complete authorization solution: the bits involving role assignment. What you **do** with those roles is up to you!

If you just need to recognize a few users as being admins, slap a flag into your user schema and be done with it. But if you have more going on and need finer-grained control, maybe Rolex can help with that.

## Examples

```elixir
import Rolex

alias MyApp.Users.User
alias MyApp.Tasks.Task

# grant some roles to a user
user |> Rolex.grant_role!(:editor, on: task)

# list all users with a role on that task
Rolex.where_granted_to(User, role: :editor, on: task) |> MyApp.Repo.all()

# fetch user's permissions for future role checks
permissions = Rolex.load_permissions_granted_to(user)

# do these permissions grant :editor on any tasks?
permissions |> granted?(role: :editor, on: {:any, Task})
```

## Installation

Add `rolex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rolex, "~> 0.4.0"}
  ]
end
```

Create and run a migration to set up the `permissions` table.

```shell
  $ mix rolex.install
end
```

Configure Rolex so it knows which Ecto repo to work with.

```elixir
# config.exs
config :rolex, repo: MyApp.Repo
```

That's it! You're ready to go.

## Permission control

Rolex adopts a SQL-like approach to role assignment, using a hierarchy of "permissions" to determine which **roles** are assigned **to** a subject ("who") **on** an object ("what").

Roles are specified as atoms; e.g. `:admin` or `:editor`.

A permission's subject and object constrain the scope of entities to which the permission applies, and may be specified as:

- `:all` - a special atom for granting or denying ALL of something
- schema - any Ecto schema module
- entity - any Ecto schema entity; e.g. `%User{id: 123}`

When you **grant** or **deny** roles, permissions are created. Rolex can then inspect the full set of "grant" and "deny" permissions to determine which roles, if any, are actually granted. Subject and object scopes are considered, and "deny" permissions override "grant" permissions.

When you **revoke** roles, permissions are deleted.

## Ergonomics

Nearly everything you can do in Rolex has the form of a function taking one to three pieces of information as a keyword list.

- `role` - an atom naming the role
- `to` (or `from`) - the permission subject scope ("who")
- `on` - the permission object scope ("what")

Functions with arity 1 accept them in that form:

```elixir
# standard versions return an {:ok, value} tuple
{:ok, %Rolex.Permission{}} = Rolex.grant(role: :admin, to: user)
{:ok, %Rolex.Permission{}} = Rolex.grant(role: :superadmin, to: user)

# "bang" versions return the value on succeess or raise otherwise
%Rolex.Permission{} = Rolex.deny!(role: :admin, to: user, on: task)
```

There are also "sugared" versions of arity 2, where the first argument supplies the option of your choice. Permission control (i.e. grant, deny, revoke) functions of this form return this first argument as their value, making them pipeable.

```elixir
# same as everything above, except piping the user along
user
|> Rolex.grant_to!(role: :admin)
|> Rolex.grant_to!(role: :superadmin)
|> Rolex.deny_to!(role: :admin, on: task)
```

Functions of arity 2 are also used for Ecto query scoping, where Rolex needs to know whether the query represents potential subjects or objects.

```elixir
# only tasks on which :admin has been granted to user
from(t in Task) |> Rolex.where_granted_on(role: :admin, to: user)
```

## Granting, denying, revoking

`grant/1`, `deny/1`, and `revoke/1` take the full set of options, while "bang" and arity 2 flavors of each (e.g. `grant!/1`, `grant_to/2`) are available for piping and better semantics.

Rolex also offers `Ecto.Multi` support with `multi_*` variants of each non-"bang" function.

### Examples

```elixir
# grant :admin to user -- [to: :all, on: all] is implied
Rolex.grant_to!(user, role: :admin)

# grant :approver to user on all Tasks... except the one
user
|> Rolex.grant_to!(role: :approver, on: Task)
|> Rolex.deny_to!(role: :approver, on: task)

# revoke that last permission to restore :approver on that task
Rolex.revoke!(from: user, role: :approver, on: task)
```

## Scoping queries

Rolex provides functions for scoping a subject or object query according to granted role requirements. Pipe in your query and set requirements via options. You'll get back a scoped query in return, ready to execute or modify further.

```elixir
# only users to which :admin has been granted on all tasks
from(u in User)
|> Rolex.where_granted_to(role: :admin, on: Task)
|> MyRepo.all()

# only tasks on which :admin has been granted to user
from(t in Task)
|> Rolex.where_granted_on(role: :admin, to: user)
|> MyRepo.all()
```

What if we wanted to see users to whom `:admin` has been granted on _any_ task? This is very different from having a role on _all_ tasks, so Rolex introduces `:any` for this purpose:

```elixir
# only users with the :admin role on something
from(u in User)
|> Rolex.where_granted_to(role: :admin, on: :any)
|> MyRepo.all()

# only users on which :admin has been granted to at least one task
from(u in User)
|> Rolex.where_granted_to(role: :admin, on: {:any, Task})
|> MyRepo.all()
```

## Role checks

Querying the database every time a role question comes up is probably not optimal.

Fortunately, permissions are just rules. Any arbitrary subject and object can be evaluated against a list of these rules to determine which (and whether any!) roles are granted.

Rolex's query scoping functions do that evaluation on a database, at scale. For fine-grained role checks in your application, Rolex also offers functions to do exactly the same evaluation on a list of permissions, in memory.

```elixir
# load permissions granted to the user
# keep them somewhere; e.g. socket assign, user virtual field, whatever
permissions = Rolex.load_permissions_granted_to(user)

# whenever you want to check roles, no need to talk to the database
permissions |> Rolex.granted_role?(:admin, on: task)
```

## Integrations

Rolex only deals with role management. For simple apps, you're probably fine to just check a user's roles to see where they can go and what they can do. As your requirements scale up in complexity, though, you may wish to combine Rolex with something else.

### LetMe

My apps use [LetMe](https://github.com/woylie/let_me) policies to authorize actions, with the [check module](https://hexdocs.pm/let_me/readme.html#check-module) defining `role/3` as a call to `Rolex.granted?/2`.

## Status

This library is actively maintained, because I'm using it in my own apps. Although I'm just one guy, please feel free to open an issue with questions. I'll help if I can!
