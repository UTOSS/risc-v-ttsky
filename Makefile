# Convert SystemVerilog (.sv) files to Verilog (.v) using sv2v

SV_FILES := $(shell find src/ -follow -name "*.sv" -type f 2>/dev/null | grep -v '/src/src')
INCLUDE_FLAGS := -I src/utoss-risc-v/
DEFINE_FLAGS := -DUTOSS_RISCV_HARDENING
V_FILES := $(SV_FILES:.sv=.sv2v.v)

.PHONY: sv2v clean help

sv2v:
	@mkdir -p .sv2v_temp
	@sv2v $(INCLUDE_FLAGS) $(DEFINE_FLAGS) $(SV_FILES) -w .sv2v_temp
	@for svfile in $(SV_FILES); do \
		module_name=$$(basename "$$svfile" .sv); \
		if [ -f ".sv2v_temp/$$module_name.v" ]; then \
			mv ".sv2v_temp/$$module_name.v" "$$(dirname "$$svfile")/$$module_name.sv2v.v"; \
		fi; \
	done
	@rm -rf .sv2v_temp

clean:
	@rm -f $(V_FILES)
