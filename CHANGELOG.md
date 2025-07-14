# Changelog

## v0.3.0

- **Breaking**: All handlers should now have an argument sink to accept extra arguments.
  This can be accomplished by using for example `(data, ..args) => upper(data)`
  instead of previously directly passing `upper`.

