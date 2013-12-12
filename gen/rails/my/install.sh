#!/bin/sh

RAILS_ENV=production rake db:create
RAILS_ENV=production rake db:migrate
#RAILS_ENV=bootstrap rake db:create
#RAILS_ENV=bootstrap rake db:migrate
#RAILS_ENV=production rake db:seed -- load seed data from prime (system prime)

