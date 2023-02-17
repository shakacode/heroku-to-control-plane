<!-- NOTE: This file is automatically generated by running `script/generate_commands_docs`. Do NOT edit it manually. -->

### Common Options

```
-a XXX, --app XXX         app ref on Control Plane (GVC)
```

This `-a` option is used in most of the commands and will pick all other app configurations from the project-specific
`.controlplane/controlplane.yml` file.

### Commands

### `build-image`

- Builds and pushes the image to Control Plane
- Automatically assigns image numbers, e.g., `app:1`, `app:2`, etc.
- Uses `.controlplane/Dockerfile`

```sh
cpl build-image -a $APP_NAME
```

### `config`

- Displays current configs (global and app-specific)

```sh
# Shows the global config.
cpl config

# Shows both global and app-specific configs.
cpl config -a $APP_NAME
```

### `delete`

- Deletes the whole app (GVC with all workloads and all images)
- Will ask for explicit user confirmation

```sh
cpl delete -a $APP_NAME
```

### `env`

- Displays app-specific environment variables

```sh
cpl env -a $APP_NAME
```

### `exists`

- Shell-checks if an application (GVC) exists, useful in scripts, e.g.:

```sh
if [ cpl exists -a $APP_NAME ]; ...
```

### `latest-image`

- Displays the latest image name

```sh
cpl latest-image -a $APP_NAME
```

### `logs`

- Light wrapper to display tailed raw logs for app/workload syntax

```sh
# Displays logs for the default workload (`one_off_workload`).
cpl logs -a $APP_NAME

# Displays logs for a specific workload.
cpl logs -a $APP_NAME -w $WORKLOAD_NAME
```

### `open`

- Opens the app endpoint URL in the default browser

```sh
# Opens the endpoint of the default workload (`one_off_workload`).
cpl open -a $APP_NAME

# Opens the endpoint of a specific workload.
cpl open -a $APP_NAME -w $WORKLOAD_NAME
```

### `promote-image`

- Promotes the latest image to app workloads

```sh
cpl promote-image -a $APP_NAME
```

### `ps`

- Shows running replicas in app

```sh
# Shows running replicas in app, for all workloads.
cpl ps -a $APP_NAME

# Shows running replicas in app, for a specific workload.
cpl ps -a $APP_NAME -w $WORKLOAD_NAME
```

### `ps:restart`

- Forces redeploy of workloads in app

```sh
# Forces redeploy of all workloads in app.
cpl ps:restart -a $APP_NAME

# Forces redeploy of a specific workload in app.
cpl ps:restart -a $APP_NAME -w $WORKLOAD_NAME
```

### `ps:start`

- Starts workloads in app

```sh
# Starts all workloads in app.
cpl ps:start -a $APP_NAME

# Starts a specific workload in app.
cpl ps:start -a $APP_NAME -w $WORKLOAD_NAME
```

### `ps:stop`

- Stops workloads in app

```sh
# Stops all workloads in app.
cpl ps:stop -a $APP_NAME

# Stops a specific workload in app.
cpl ps:stop -a $APP_NAME -w $WORKLOAD_NAME
```

### `run`

- Runs one-off **_interactive_** replicas (analog of `heroku run`)
- Uses `Standard` workload type and `cpln exec` as the execution method, with CLI streaming
- May not work correctly with tasks that last over 5 minutes (there's a Control Plane scaling bug at the moment)

> **IMPORTANT:** Useful for development where it's needed for interaction, and where network connection drops and
> task crashing are tolerable. For production tasks, it's better to use `cpl run:detached`.

```sh
# Opens shell (bash by default).
cpl run -a $APP_NAME

# Runs command, displays output, and exits shell.
cpl run ls / -a $APP_NAME
cpl run rails db:migrate:status -a $APP_NAME

# Runs command and keeps shell open.
cpl run rails c -a $APP_NAME

# Uses a different image (which may not be promoted yet).
cpl run rails db:migrate -a $APP_NAME --image appimage:123 # Exact image name
cpl run rails db:migrate -a $APP_NAME --image latest       # Latest sequential image
```

### `run:detached`

- Runs one-off **_non-interactive_** replicas (close analog of `heroku run:detached`)
- Uses `Cron` workload type with log async fetching
- Implemented with only async execution methods, more suitable for production tasks
- Has alternative log fetch implementation with only JSON-polling and no WebSockets
- Less responsive but more stable, useful for CI tasks

```sh
cpl run:detached rails db:prepare -a $APP_NAME
cpl run:detached 'LOG_LEVEL=warn rails db:migrate' -a $APP_NAME

# Uses some other image.
cpl run:detached rails db:migrate -a $APP_NAME --image /some/full/image/path

# Uses latest app image (which may not be promoted yet).
cpl run:detached rails db:migrate -a $APP_NAME --image latest

# Uses a different image (which may not be promoted yet).
cpl run:detached rails db:migrate -a $APP_NAME --image appimage:123 # Exact image name
cpl run:detached rails db:migrate -a $APP_NAME --image latest       # Latest sequential image
```

### `setup`

- Applies application-specific configs from templates (e.g., for every review-app)
- Publishes (creates or updates) those at Control Plane infrastructure
- Picks templates from the `.controlplane/templates` directory
- Templates are ordinary Control Plane templates but with variable preprocessing

**Preprocessed template variables:**

```
APP_GVC      - basically GVC or app name
APP_LOCATION - default location
APP_ORG      - organization
APP_IMAGE    - will use latest app image
```

```sh
# Applies single template.
cpl setup redis -a $APP_NAME

# Applies several templates (practically creating full app).
cpl setup gvc postgres redis rails -a $APP_NAME
```