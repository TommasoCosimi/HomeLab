# Further Improvements
Once the container is spun up, it is possible to run some operations which can improve performances.
```bash
# Clean up the Database
docker exec -ti --user www-data nextcloud_app php occ maintenance:repair --include-expensive
# Fix the indices
docker exec -ti --user www-data nextcloud_app php occ db:add-missing-indices
# Set the low usage window for Cron Jobs to run
docker exec -ti --user www-data nextcloud_app php occ config:system:set maintenance_window_start --type=integer --value=8
```