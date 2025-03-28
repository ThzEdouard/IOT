#!/bin/bash

echo "Initializing local GitLab repository..."
echo "Checking if GitLab repository 'iot' already exists..."

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/gitlab/iot")

if [ "$HTTP_CODE" = "200" ]; then
	echo "Repository 'iot' already exists. Skipping creation."
	exit 0
else
	echo "Creating 'iot' repository..."

	docker exec gitlab bash -c "cat > /tmp/create_repo.rb << 'EOL'
begin
	user = User.find_by(username: 'gitlab')
	unless user
		puts 'User gitlab not found. Please run make setup-gitlab-namespace first.'
		exit(1)
	end

	project = Projects::CreateService.new(
		user,
		{
			name: 'iot',
			path: 'iot',
			visibility_level: Gitlab::VisibilityLevel::PUBLIC,
			initialize_with_readme: false
		}
	).execute

	if project.persisted?
		puts \"Repository 'iot' created successfully.\"
	else
		puts \"Failed to create repository: #{project.errors.full_messages.join(', ')}\"
		exit(1)
	end
rescue => e
	puts \"Error: #{e.message}\"
	exit(1)
end
EOL"

	docker exec gitlab gitlab-rails runner /tmp/create_repo.rb
	docker exec gitlab rm /tmp/create_repo.rb

	echo "Repository 'iot' created successfully."
fi
