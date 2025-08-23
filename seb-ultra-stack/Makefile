DOMAIN ?= example.com
EMAIL ?= admin@$(DOMAIN)

up:
	docker compose up -d --build
	@echo '→ When first up, run: make wp'

down:
	docker compose down

wp:
	docker compose exec php bash -lc 'bash /docker/wordpress/init.sh || true'

ssl-http:
	docker compose run --rm certbot certonly --webroot -w /var/www/html -d $(DOMAIN) -m $(EMAIL) --agree-tos --non-interactive
