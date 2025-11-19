set(TARGET app.elf)
set(BOARD tangnano9k)

# Folders
set(SRC_DIR ${PROJECT_SOURCE_DIR}/source)
set(BSP_DIR ${SRC_DIR}/bsp)

# Main application
set(SRCS_APP
  ${SRC_DIR}/main.c
  ${SRC_DIR}/runtime.c  
)

set(INCL_APP
  ${SRC_DIR}
)

set(DEFS_APP
  $<$<CONFIG:DEBUG>: DEBUG> 
)

# Board support package
set(SRCS_BSP 
  ${BSP_DIR}/serial.c
)  

set(INCL_BSP
  ${BSP_DIR}
)

set(DEFS_BSP
)

# Board support: specific sources, includes, and compiler flags
if(NOT DEFINED BOARD)
  message(FATAL_ERROR "BOARD type must be set")
endif()

# Board specific support 
message(STATUS "Configuring board support for '${BOARD}'")

  # TangNano9K (GW1NAR-8)
if(BOARD STREQUAL tangnano9k)   
  set(LINKER_SCRIPT linker.lds)  
  list(APPEND SRCS_BSP ${BSP_DIR}/${BOARD}/startup.s)
endif()

# Build targets
add_executable(${TARGET} ${SRCS_APP} ${SRCS_BSP})
target_include_directories(${TARGET} PRIVATE ${INCL_APP} ${INCL_BSP})
target_compile_definitions(${TARGET} PRIVATE ${DEFS_APP} ${DEFS_BSP})
target_link_options(${TARGET} PRIVATE -T ${BSP_DIR}/${BOARD}/${LINKER_SCRIPT})
target_link_libraries(${TARGET} PRIVATE gcc)  

add_custom_command(TARGET ${TARGET} POST_BUILD
  COMMAND ${CMAKE_SIZE} ${TARGET}
  COMMAND ${CMAKE_OBJCOPY} -O ihex ${TARGET} ${TARGET}.hex
  COMMAND ${CMAKE_OBJCOPY} -O binary ${TARGET} ${TARGET}.bin
  COMMAND ${CMAKE_OBJDUMP} -d -S ${TARGET} > ${TARGET}.s
  COMMAND ${CMAKE_COMMAND} -E chdir ${CMAKE_CURRENT_BINARY_DIR} 
          python3 ${PROJECT_SOURCE_DIR}/tools/bin_to_hex.py ${TARGET}.bin
COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/firmware_b0.hex ${PROJECT_SOURCE_DIR}/../hw/handover/firmware_b0.hex
  # Copy hex files to location expected by FPGA build
  COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/firmware_b0.hex ${PROJECT_SOURCE_DIR}/../hw/handover/firmware_b0.hex
  COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/firmware_b1.hex ${PROJECT_SOURCE_DIR}/../hw/handover/firmware_b1.hex
  COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/firmware_b2.hex ${PROJECT_SOURCE_DIR}/../hw/handover/firmware_b2.hex
  COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/firmware_b3.hex ${PROJECT_SOURCE_DIR}/../hw/handover/firmware_b3.hex
)

