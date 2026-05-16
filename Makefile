.PHONY: all build up down start stop restart clean fclean re logs ps

COMPOSE		= docker compose -f srcs/docker-compose.yml
DATA_PATH	= /home/mkurkar/data

all: build up

build:
	@echo "Creating data directories..."
	@mkdir -p $(DATA_PATH)/mysql
	@mkdir -p $(DATA_PATH)/wordpress
	@echo "Building Docker images..."
	@$(COMPOSE) build

up:
	@echo "Starting containers..."
	@$(COMPOSE) up -d

down:
	@echo "Stopping and removing containers..."
	@$(COMPOSE) down

start:
	@echo "Starting containers..."
	@$(COMPOSE) start

stop:
	@echo "Stopping containers..."
	@$(COMPOSE) stop

restart: stop start

logs:
	@$(COMPOSE) logs -f

ps:
	@$(COMPOSE) ps

clean: down
	@echo "Removing project images..."
	@$(COMPOSE) down --rmi all 2>/dev/null || true

fclean: down
	@echo "Removing project images, volumes and data..."
	@$(COMPOSE) down --rmi all -v 2>/dev/null || true
	@sudo rm -rf $(DATA_PATH)/mysql
	@sudo rm -rf $(DATA_PATH)/wordpress
	@echo "Full cleanup complete!"

re: fclean all
