#!/bin/sh

RAILS_ENV=production rake db:create
RAILS_ENV=production rake db:migrate
#RAILS_ENV=production rake db:seed -- load seed database from prime (system prime)

