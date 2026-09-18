# Discord Notification Setup

`notify-discord.yml` posts to a Discord channel via a plain [webhook URL](https://support.discord.com/hc/en-us/articles/228383668) — `DISCORD_WEBHOOK_URL` (and optionally `DISCORD_ALERT_WEBHOOK_URL` for failure alerts, if you want a separate channel). There's no bot token, OAuth, or gateway connection involved; a webhook URL is all the workflow needs.

Two ways to get that URL:

## Option A: Create the webhook directly in the channel

The normal path — no bot required.

1. In Discord, go to the target channel's settings → **Integrations** → **Webhooks** → **New Webhook**.
2. Name it and pick the channel it should post to (or reuse an existing webhook).
3. Click **Copy Webhook URL**.
4. Store it as a secret on the consumer repo (or org): `DISCORD_WEBHOOK_URL`. Repeat for a second webhook/channel if you want `DISCORD_ALERT_WEBHOOK_URL` to go somewhere else.
5. Pass it through `rust-release.yml`:

```yaml
jobs:
  release:
    uses: oxHive/pipelines/.github/workflows/rust-release.yml@v2
    with:
      notify-provider: discord
      # ...
    secrets: inherit
    # or, if not using inherit:
    # secrets:
    #   DISCORD_WEBHOOK_URL: ${{ secrets.DISCORD_WEBHOOK_URL }}
    #   DISCORD_ALERT_WEBHOOK_URL: ${{ secrets.DISCORD_ALERT_WEBHOOK_URL }}
```

## Option B: Create the webhook via a bot application

Useful when you're provisioning webhooks programmatically (e.g. scripting setup across many repos/channels) instead of clicking through the UI each time. A bot with `Manage Webhooks` permission in the target channel can create one via the API and hand you back the same kind of URL as Option A.

1. Create an application at the [Discord Developer Portal](https://discord.com/developers/applications) and add a bot to it.
2. Under **OAuth2 → URL Generator**, select the `bot` scope and the `Manage Webhooks` permission, then use the generated URL to invite the bot to your server.
3. Grant the bot's role `Manage Webhooks` on the target channel (channel permission overrides, or a server-wide role).
4. Create the webhook via the API, authenticated as the bot:

   ```bash
   curl -X POST "https://discord.com/api/v10/channels/<CHANNEL_ID>/webhooks" \
     -H "Authorization: Bot <BOT_TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{"name": "release-notifier"}'
   ```

   The response's `url` field (or `https://discord.com/api/webhooks/{id}/{token}` built from `id`/`token`) is the same webhook URL as Option A.
5. Store and wire it up as `DISCORD_WEBHOOK_URL` / `DISCORD_ALERT_WEBHOOK_URL` exactly as in Option A — the bot token itself isn't needed by the workflow and doesn't need to be stored anywhere.

## Optional: sender name/avatar

`rust-release.yml`'s `notify-discord-username` / `notify-discord-avatar-url` inputs (forwarded to `notify-discord.yml`'s `username`/`avatar_url`) override the webhook's default sender display per call. Leave them empty to use whatever's configured on the webhook itself.
