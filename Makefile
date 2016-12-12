TOP_NAME=sdram_test
ARACHNE_OPTS=-d 8k -P ct256

${TOP_NAME}.bin: ${TOP_NAME}.v ${TOP_NAME}.pcf
	yosys -s build.yosys -p "write_blif -gates -attr -param ${TOP_NAME}.blif"
	arachne-pnr $(ARACHNE_OPTS) ${TOP_NAME}.blif -p ${TOP_NAME}.pcf > ${TOP_NAME}.txt
	icepack ${TOP_NAME}.txt ${TOP_NAME}.bin

clean:
	rm -f ${TOP_NAME}.blif ${TOP_NAME}.txt ${TOP_NAME}.bin

flash: ${TOP_NAME}.bin
	iceprog ${TOP_NAME}.bin
