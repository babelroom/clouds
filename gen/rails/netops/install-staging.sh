#!/bin/sh

RAILS_ENV=test rake db:create
RAILS_ENV=test rake db:migrate
RAILS_ENV=test rake db:seed

