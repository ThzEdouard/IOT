#!/bin/bash

if ! docker ps | grep -q gitlab; then
	echo "The GitLab container is not running. Please start it first."
	exit 1
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/gitlab")

echo "Checking if 'gitlab' user already exists..."

if [ "$HTTP_CODE" = "200" ]; then
	echo "The 'gitlab' user already exists."
else
	echo "Creating 'gitlab' user..."

	docker exec gitlab bash -c "cat > /tmp/create_user.rb << 'EOL'
begin
	user = User.new(
		username: 'gitlab',
		name: 'gitlab',
		email: 'gitlab@example.com',
		password: 'G!tL@bS3cur3P@ssw0rd!,
		password_confirmation: 'G!tL@bS3cur3P@ssw0rd!,
		admin: true
	)
	user.assign_personal_namespace(Organizations::Organization.default_organization)
	user.skip_confirmation!
	user.save!
	puts 'User gitlab created successfully.'
rescue => e
	puts \"Error: #{e.message}\"
	exit(1)
end
EOL"

	docker exec gitlab gitlab-rails runner /tmp/create_user.rb
	docker exec gitlab rm /tmp/create_user.rb

	echo "User 'gitlab' created successfully."
fi

echo "Access GitLab at http://localhost:8080"
echo "Username: gitlab"
echo "Password: G!tL@bS3cur3P@ssw0rd!"
