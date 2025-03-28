#!/bin/bash

echo "Adding your SSH public key to GitLab user..."

PUBLIC_KEY_FILE=$(ls ~/.ssh/id_*.pub 2>/dev/null | head -n 1)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/-/user_settings/ssh_keys/1")

if [ -z "$PUBLIC_KEY_FILE" ]; then
	echo "No SSH public key found. Please generate one with 'ssh-keygen' first."
	exit 1
fi

echo "Using key: $PUBLIC_KEY_FILE"
PUBLIC_KEY=$(cat "$PUBLIC_KEY_FILE")

if [ "$HTTP_CODE" != "404" ]; then
	echo "The SSH key is already added to the user 'gitlab'."
else
	echo "Adding SSH key to user 'gitlab'..."
	docker exec gitlab bash -c "cat > /tmp/add_ssh_key.rb << 'EOL'
	begin
	user = User.find_by(username: 'gitlab')
	unless user
		puts 'User gitlab not found. Please run make setup-gitlab-namespace first.'
		exit(1)
	end

	key_content = File.read('/tmp/ssh_key.pub').strip

	key = Key.new(
		title: 'Local Development Key',
		key: key_content,
		user_id: user.id
	)

	if key.save
		puts \"SSH key added successfully.\"
	else
		puts \"Failed to add SSH key: #{key.errors.full_messages.join(', ')}\"
		exit(1)
	end
rescue => e
	puts \"Error: #{e.message}\"
	exit(1)
end
EOL"

	echo "$PUBLIC_KEY" | docker exec -i gitlab bash -c "cat > /tmp/ssh_key.pub"

	docker exec gitlab gitlab-rails runner /tmp/add_ssh_key.rb
	docker exec gitlab rm /tmp/add_ssh_key.rb /tmp/ssh_key.pub

	echo "SSH key added to GitLab user 'gitlab'."
fi
