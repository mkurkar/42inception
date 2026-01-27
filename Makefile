.PHONY: all build up down start stop restart clean fclean re logs ps

DATA_PATH = /home/mkurkar/data

all: build up

build:
	@echo "Creating data directories..."
	@mkdir -p $(DATA_PATH)/mysql
	@mkdir -p $(DATA_PATH)/wordpress
	@echo "Building Docker images..."
	@docker compose -f srcs/docker-compose.yml build

up:
	@echo "Starting containers..."
	@docker compose -f srcs/docker-compose.yml up -d

down:
	@echo "Stopping and removing containers..."
	@docker compose -f srcs/docker-compose.yml down

start:
	@echo "Starting containers..."
	@docker compose -f srcs/docker-compose.yml start

stop:
	@echo "Stopping containers..."
	@docker compose -f srcs/docker-compose.yml stop

restart: stop start

logs:
	@docker compose -f srcs/docker-compose.yml logs -f

ps:
	@docker compose -f srcs/docker-compose.yml ps

clean: down
	@echo "Removing Docker images..."
	@docker rmi -f $$(docker images -q) 2>/dev/null || true

fclean: clean
	@echo "Removing volumes and data..."
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@sudo rm -rf $(DATA_PATH)/mysql
	@sudo rm -rf $(DATA_PATH)/wordpress
	@echo "Full cleanup complete!"

re: fclean all
