deploy:
	screen -X stuff ^E
	../../file_transfer/filetransfer_screen.sh main.r3 rosserial.r3 rosmsg.r3
	screen -X stuff "r3c -Wall -orosserver main.r3^M"
	screen -X stuff "./rosserver^M"

