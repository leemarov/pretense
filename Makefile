BUILD_DIR := ./build

MIST_FILEPATH := resources/mist_4_5_121_custom.lua

MIZ_FP_CAUCASUS_COLD := resources/miz/Pretense_caucasus_1.7.2.miz
MIZ_FP_CAUCASUS_HOT := resources/miz/Pretense_hotstart_caucasus_1.7.2.miz
MIZ_FP_SYRIA_COLDWAR_COLD := resources/miz/Pretense_syria_cw_1.7.2.miz
MIZ_FP_SYRIA_COLDWAR_HOT := resources/miz/Pretense_hotstart_syria_cw_1.7.2.miz
MIZ_FP_SYRIA_MODERN_COLD := resources/miz/Pretense_syria_m_1.7.2.miz
MIZ_FP_SYRIA_MODERN_HOT := resources/miz/Pretense_hotstart_syria_m_1.7.2.miz

INIT_FP_CAUCASUS := resources/init_caucasus.lua
INIT_FP_SYRIA_COLDWAR := resources/init_syria_cw.lua
INIT_FP_SYRIA_MODERN := resources/init_syria_m.lua

PRETENSE_COMPILE_FP := build/pretense_compiled.lua

BUILD_COMMAND := python scripts/build.py $(MIST_FILEPATH) $(PRETENSE_COMPILE_FP)

default: all

.PHONY: all
all: caucasus_modern syria_coldwar syria_modern

.PHONY:$(PRETENSE_COMPILE_FP)
$(PRETENSE_COMPILE_FP):
	python scripts/recompile.py $(PRETENSE_COMPILE_FP)


.PHONY: caucasus_modern caucasus_modern_hot caucasus_modern_cold
caucasus_modern: caucasus_modern_hot caucasus_modern_cold

caucasus_modern_hot: $(PRETENSE_COMPILE_FP)
	$(BUILD_COMMAND) $(MIZ_FP_CAUCASUS_HOT) $(INIT_FP_CAUCASUS)

caucasus_modern_cold: $(PRETENSE_COMPILE_FP)
	$(BUILD_COMMAND) $(MIZ_FP_CAUCASUS_COLD) $(INIT_FP_CAUCASUS)


.PHONY: syria_modern syria_modern_hot syria_modern_cold
syria_modern: syria_modern_hot syria_modern_cold

syria_modern_hot: $(PRETENSE_COMPILE_FP)
	$(BUILD_COMMAND) $(MIZ_FP_SYRIA_MODERN_HOT) $(INIT_FP_SYRIA_MODERN)

syria_modern_cold: $(PRETENSE_COMPILE_FP)
	$(BUILD_COMMAND) $(MIZ_FP_SYRIA_MODERN_COLD) $(INIT_FP_SYRIA_MODERN)


.PHONY: syria_coldwar syria_coldwar_hot syria_coldwar_cold
syria_coldwar: syria_coldwar_hot syria_coldwar_cold

syria_coldwar_hot: $(PRETENSE_COMPILE_FP)
	$(BUILD_COMMAND) $(MIZ_FP_SYRIA_COLDWAR_HOT) $(INIT_FP_SYRIA_COLDWAR)

syria_coldwar_cold: $(PRETENSE_COMPILE_FP)
	$(BUILD_COMMAND) $(MIZ_FP_SYRIA_COLDWAR_COLD) $(INIT_FP_SYRIA_COLDWAR)