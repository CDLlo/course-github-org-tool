cd anacapa/
rm -rf tmp/
echo "Performing Setup..."
bundle install
bundle exec rake db:create
bundle exec rake db:migrate
echo "Starting rails server..."
rails s -b '0.0.0.0' -p 3000
