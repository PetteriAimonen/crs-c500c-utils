deploy:
	screen -X stuff ^E
	../file_transfer/filetransfer_screen.sh rosserial_test.r3 rosserial_packets.r3
	screen -X stuff "r3c rosserial_test.r3^M"
	screen -X stuff "./rosserial_test^M"

