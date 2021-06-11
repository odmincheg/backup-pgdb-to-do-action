# backup-pgdb-to-do-action
[GitHub Action](https://github.com/features/actions) for backing up PostgreSQL DB to DigitalOcean space.

This action creating backup from your remote PostgreSQL server and store it in `backups` folder inside the container. 

You can attach several actions available at the [Marketplace](https://github.com/marketplace?type=actions).

## Example Usecase
```yaml
name: Backup TO DigitalOcean space
env:
  BACKUPURL: "http://example.com/url/to/backup/some-backup.psql.gz"
  
on: [workflow_dispatch]

jobs:
  build:
    name: DUMP
    runs-on: ubuntu-latest

    steps:
    - name: checkout
      uses: actions/checkout@v2

    - name: Backup Staging Postgres DB
      uses: odmincheg/backup-pgdb-to-do-action@latest
      with:
        db_type: postgres
        db_action: backup
        db_host: ${{ secrets.STG_DB_HOST }}
        db_port: ${{ secrets.STG_DB_PORT }}
        db_user: ${{ secrets.STG_DB_USER }}
        db_pass: ${{ secrets.STG_DB_PASS }}
        db_name: ${{ secrets.STG_DB_name }}
        space_access_key_id: ${{ secrets.DO_AWS_ACCESS_KEY_ID }}
        space_secret_access_key: ${{ secrets.DO_AWS_SECRET_ACCESS_KEY }}
        space_name: ${{ secrets.DO_SPACE_NAME }}
        space_region: ${{ secrets.REGION_NAME }} # nyc3

    - name: Restore Postgres DB on remote host
      uses: odmincheg/backup-pgdb-to-do-action@latest
      with:
        db_type: postgres
        db_action: restore
        db_host: ${{ secrets.ANOTHER_DB_HOST }}
        db_port: ${{ secrets.ANOTHER_DB_PORT }}
        db_user: ${{ secrets.ANOTHER_DB_USER }}
        db_pass: ${{ secrets.ANOTHER_DB_PASS }}
        db_name: ${{ secrets.ANOTHER_DB_name }}
        db_backup_url: ${{ env.BACKUPURL }}
```

## Input variables

See [action.yml](./action.yml) for more detailed information.

 * db_action: here you can set what exactly do you want to do with DB `backup` or `restore`
 * db_backup_url: public url where action can get backup and restore it on remote server. Backup should be in gz archive
 * db_host: PostreSQL host
 * db_port: PostreSQL port
 * db_user: PostreSQL username
 * db_pass: PostreSQL password
 * db_name: PostreSQL database name
 * space_access_key_id: DigitalOcean API access key
 * space_secret_access_key: DigitalOcean API secret access key
 * space_name: DigitalOcean space name 
 * space_region: DigitalOcean region # ny3

## Disclaimer
- Check your custom scripts properly.
- Pass all credentials from Github Secrets.
- The best way is to use DB Credentials with Read-only access to database.
- Use it at your own risk!

## Enjoy.
