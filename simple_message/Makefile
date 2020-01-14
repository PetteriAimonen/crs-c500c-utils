deploy:
	/bin/echo -e "\x05\n\ncd /app/ros\n" | timeout 1 netcat localhost 11010 || true
	../file_transfer/filetransfer_netcat.sh robot_status_server.r3 robot_control_server.r3 serial_framing.r3
	/bin/echo -e "r3c -Wall robot_status_server.r3" | timeout 5 netcat localhost 11010 || true
	/bin/echo -e "r3c -Wall robot_control_server.r3" | timeout 5 netcat localhost 11010 || true
	/bin/echo -e "./robot_status_server &" | timeout 1 netcat localhost 11010 || true
	/bin/echo -e "./robot_control_server &" | timeout 1 netcat localhost 11010 || true

