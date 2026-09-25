echo "Saving docker image as image.tar..."
docker save sakthi-u24:latest -o image.tar
echo "Compressing and creating archive bundle.tar.gz..."
tar czf bundle.tar.gz --exclude=./workspace image.tar --exclude=./bundle.tar.gz ./*
echo "Removing image.tar file..."
rm image.tar
