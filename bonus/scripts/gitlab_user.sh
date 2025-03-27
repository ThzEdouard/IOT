# Vérifier si le conteneur GitLab est en cours d'exécution
if ! docker ps | grep -q gitlab; then
    echo "Le conteneur GitLab n'est pas en cours d'exécution. Veuillez d'abord le démarrer."
    exit 1
fi

# Vérifier si l'utilisateur 'gitlab' existe déjà
if docker exec gitlab gitlab-rails runner "puts User.find_by(username: 'gitlab') ? 'EXISTS' : 'NOT_FOUND'" | grep -q "EXISTS"; then
    echo "L'utilisateur 'gitlab' existe déjà."
else
    echo "Création de l'utilisateur 'gitlab'..."
    docker exec gitlab gitlab-rails runner "
        user = User.new(
          username: 'gitlab',
          name: 'gitlab',
          email: 'gitlab@example.com',
          password: 'G!tL@bS3cur3P@ssw0rd!',
          password_confirmation: 'G!tL@bS3cur3P@ssw0rd!',
          admin: true
        )
        user.assign_personal_namespace(Organizations::Organization.default_organization)
        user.skip_confirmation!
        user.save!
        puts 'Utilisateur gitlab créé avec succès.'
    "
fi
