all: transfer_to_bin

transfer_to_bin: ./functions
	@echo "Transfering short commands to /usr/bin..."
	sudo cp ./functions/docker/* /usr/bin
	sudo cp ./functions/git/* /usr/bin
	sudo cp ./functions/go/* /usr/bin
	sudo cp ./functions/java/* /usr/bin
	@echo "Done"
