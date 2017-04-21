# Central

Central is a gem that use `redis` or `consul` as configuration server that use async logic to
manage configuration.

For now it only support `connection-pool` instance of `redis`, but it can be easily extended to
use `consul` or `redis-cluster`.

This repo contains :
- `central`       - core library for the whole engine
- `central-rails` - rails engine integeration plugin

## Architecture
