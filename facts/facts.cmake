cmake_minimum_required(VERSION 2.8)
cmake_policy(SET CMP0011 NEW)
cmake_policy(SET CMP0045 OLD)

IF(NOT DEFINED DEPENDS_PATH)
	set(DEPENDS_PATH ${CMAKI_PATH}/../../artifacts)
ENDIF()

IF(NOT DEFINED CMAKE_PREFIX_PATH)
	set(CMAKE_PREFIX_PATH ${DEPENDS_PATH}/cmaki_find_package)
ENDIF()

IF(NOT DEFINED ARTIFACTS_PATH)
	set(ARTIFACTS_PATH ${CMAKI_PATH}/../cmaki_generator)
ENDIF()

IF(NOT DEFINED DEPENDS_PATHFILE)
	# rename to ".cmaki.yml" ?
	set(DEPENDS_PATHFILE ${CMAKI_PATH}/../../artifacts.json)
ENDIF()

if(DEFINED CMAKI_DEBUG)
	MESSAGE("CMAKI_PATH = ${CMAKI_PATH}")
	MESSAGE("DEPENDS_PATH = ${DEPENDS_PATH}")
	MESSAGE("CMAKE_PREFIX_PATH = ${CMAKE_PREFIX_PATH}")
	MESSAGE("ARTIFACTS_PATH = ${ARTIFACTS_PATH}")
	MESSAGE("DEPENDS_PATHFILE = ${DEPENDS_PATHFILE}")
endif()

set(ENV{CMAKI_INFO} COMPILER)
execute_process(
	COMMAND bash cmaki_identifier.sh
	WORKING_DIRECTORY $ENV{CMAKI_INSTALL}
	OUTPUT_VARIABLE RESULT_VERSION
	OUTPUT_STRIP_TRAILING_WHITESPACE)
set(CMAKI_COMPILER "${RESULT_VERSION}")

set(ENV{CMAKI_INFO} ALL)
execute_process(
	COMMAND bash cmaki_identifier.sh
	WORKING_DIRECTORY $ENV{CMAKI_INSTALL}
	OUTPUT_VARIABLE RESULT_VERSION
	OUTPUT_STRIP_TRAILING_WHITESPACE)
set(CMAKI_PLATFORM "${RESULT_VERSION}")
message("---- detecting platform: ${CMAKI_PLATFORM}")

function(cmaki_find_package PACKAGE)

	IF(NOT DEFINED CMAKI_REPOSITORY)
		# MESSAGE(FATAL_ERROR "CMAKI_REPOSITORY: is not defined")
		set(CMAKI_REPOSITORY "http://artifacts.myftp.biz:8080")
	ENDIF()

	# 1. obtener la version actual (o ninguno en caso de no tener el artefacto)
	execute_process(
		COMMAND python ${ARTIFACTS_PATH}/get_package.py --name=${PACKAGE} --depends=${DEPENDS_PATHFILE}
		WORKING_DIRECTORY "${ARTIFACTS_PATH}"
		OUTPUT_VARIABLE RESULT_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
	if(RESULT_VERSION)
		set(VERSION_REQUEST "${RESULT_VERSION}")
		set(EXTRA_VERSION "--version=${VERSION_REQUEST}")
	else()
		set(VERSION_REQUEST "")
		set(EXTRA_VERSION "")
	endif()

	# 2.5. define flags
	if(NOT DEFINED NOCACHE_LOCAL)
		set(NO_USE_CACHE_LOCAL "FALSE")
	else()
		set(NO_USE_CACHE_LOCAL "${NOCACHE_LOCAL}")
	endif()
	if(NOT DEFINED NOCACHE_REMOTE)
		set(NO_USE_CACHE_REMOTE "FALSE")
	else()
		set(NO_USE_CACHE_REMOTE "${NOCACHE_REMOTE}")
	endif()

	#######################################################
	# 2. obtener la mejor version buscando en la cache local y remota
	execute_process(
		COMMAND python ${ARTIFACTS_PATH}/check_remote_version.py --server=${CMAKI_REPOSITORY} --artifacts=${CMAKE_PREFIX_PATH} --platform=${CMAKI_PLATFORM} --name=${PACKAGE} ${EXTRA_VERSION}
		WORKING_DIRECTORY "${ARTIFACTS_PATH}"
		OUTPUT_VARIABLE RESULT_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
	if(RESULT_VERSION)
		list(GET RESULT_VERSION 0 PACKAGE_MODE)
		list(GET RESULT_VERSION 1 PACKAGE_NAME)
		list(GET RESULT_VERSION 2 VERSION)
	else()
		set(PACKAGE_MODE "EXACT")
		set(VERSION ${VERSION_REQUEST})
		message("-- need build package ${PACKAGE} can't get version: ${VERSION_REQUEST}, will be generated.")
		# avoid remote cache, need build
		set(NO_USE_CACHE_REMOTE "TRUE")
	endif()
	#######################################################

	# 3. si no tengo los ficheros de cmake, los intento descargar
	set(depends_dir "${DEPENDS_PATH}")
	set(depends_bin_package "${depends_dir}/${PACKAGE}-${VERSION}")
	set(depends_package "${CMAKE_PREFIX_PATH}/${PACKAGE}-${VERSION}")
	set(package_marker "${depends_bin_package}/${CMAKI_PLATFORM}.cache")
	if(NOT EXISTS "${package_marker}" OR "${NO_USE_CACHE_LOCAL}")
		# pido un paquete, en funcion de:
		#		- paquete
		#		- version
		#		- plataforma
		#		- modo (COMPATIBLE / EXACT)
		# Recibo el que mejor se adapta a mis especificaciones
		# Otra opcion es enviar todos los ficheros de cmake de todas las versiones
		set(package_uncompressed_file "${CMAKE_PREFIX_PATH}/${PACKAGE}.tmp")
		set(package_cmake_filename "${PACKAGE}-${VERSION}-${CMAKI_PLATFORM}-cmake.tar.gz")
		set(http_package_cmake_filename "${CMAKI_REPOSITORY}/download.php?file=${package_cmake_filename}")
		message("download from ${http_package_cmake_filename}")
		# 4. descargo el fichero que se supone tienes los ficheros cmake
		if(NOT "${NO_USE_CACHE_REMOTE}")
			cmaki_download_file("${http_package_cmake_filename}" "${package_uncompressed_file}")
		endif()
		# Si no puede descargar el artefacto ya hecho (es que necesito compilarlo y subirlo)
		if(NOT "${COPY_SUCCESFUL}" OR "${NO_USE_CACHE_REMOTE}")

			file(REMOVE_RECURSE "${depends_bin_package}")
			file(REMOVE_RECURSE "${depends_package}")
			file(REMOVE "${package_uncompressed_file}")

			# 5. compilo y genera el paquete en local
			message("Generating artifact ${PACKAGE} ...")
			#
			# ojo: estoy hay que mejorarlo
			# no queremos usar "-o", queremos que trate de compilar las dependencias (sin -o)
			# pero queremos que evite compilar cosas que estan en cache remota
			#
			# message("command: python ${ARTIFACTS_PATH}/build.py ${PACKAGE} --depends=${DEPENDS_PATHFILE} --cmakefiles=${CMAKI_PATH} --prefix=${CMAKE_PREFIX_PATH} --third-party-dir=${CMAKE_PREFIX_PATH} --server=${CMAKI_REPOSITORY}")
			execute_process(
				COMMAND python ${ARTIFACTS_PATH}/build.py ${PACKAGE} --depends=${DEPENDS_PATHFILE} --cmakefiles=${CMAKI_PATH} --prefix=${CMAKE_PREFIX_PATH} --third-party-dir=${CMAKE_PREFIX_PATH} --server=${CMAKI_REPOSITORY} -d
				WORKING_DIRECTORY "${ARTIFACTS_PATH}"
				RESULT_VARIABLE artifacts_result
				)
			if(artifacts_result)
				message(FATAL_ERROR "can't create artifact ${PACKAGE}: error ${artifacts_result}")
				file(REMOVE_RECURSE "${depends_bin_package}")
				file(REMOVE_RECURSE "${depends_package}")
				file(REMOVE "${package_uncompressed_file}")
			endif()

			#######################################################
			# 6: obtengo la version del paquete creado
			execute_process(
				COMMAND python ${ARTIFACTS_PATH}/check_remote_version.py --server=${CMAKI_REPOSITORY} --artifacts=${CMAKE_PREFIX_PATH} --platform=${CMAKI_PLATFORM} --name=${PACKAGE} ${EXTRA_VERSION}
				WORKING_DIRECTORY "${ARTIFACTS_PATH}"
				OUTPUT_VARIABLE RESULT_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
			if(RESULT_VERSION)
				list(GET RESULT_VERSION 0 PACKAGE_MODE)
				list(GET RESULT_VERSION 1 PACKAGE_NAME)
				list(GET RESULT_VERSION 2 VERSION)
			else()
				message(FATAL_ERROR "-- not found ${PACKAGE}.")
			endif()
			#######################################################

			set(package_filename ${PACKAGE}-${VERSION}-${CMAKI_PLATFORM}.tar.gz)
			set(package_cmake_filename ${PACKAGE}-${VERSION}-${CMAKI_PLATFORM}-cmake.tar.gz)
			set(package_generated_file ${CMAKE_PREFIX_PATH}/${package_filename})
			set(package_cmake_generated_file ${CMAKE_PREFIX_PATH}/${package_cmake_filename})

			# 7. descomprimo el artefacto
			execute_process(
				COMMAND "${CMAKE_COMMAND}" -E tar zxf "${package_cmake_generated_file}"
				WORKING_DIRECTORY "${CMAKE_PREFIX_PATH}/"
				RESULT_VARIABLE uncompress_result
				)
			if(uncompress_result)
				message(FATAL_ERROR "Extracting ${package_cmake_generated_file} failed! Error ${uncompress_result}")
				file(REMOVE_RECURSE "${depends_bin_package}")
				file(REMOVE_RECURSE "${depends_package}")
				file(REMOVE "${package_uncompressed_file}")
				file(REMOVE "${package_generated_file}")
			endif()

			# y tambien descomprimo el propio tar gz
			execute_process(
				COMMAND "${CMAKE_COMMAND}" -E tar zxf "${package_generated_file}"
				WORKING_DIRECTORY "${depends_dir}/"
				RESULT_VARIABLE uncompress_result2
				)
			if(uncompress_result2)
				message(FATAL_ERROR "Extracting ${package_generated_file} failed! Error ${uncompress_result2}")
				file(REMOVE_RECURSE "${depends_bin_package}")
				file(REMOVE_RECURSE "${depends_package}")
				file(REMOVE "${package_uncompressed_file}")
				file(REMOVE "${package_generated_file}")
			endif()

			# 8. borro los 2 tar gz
			file(REMOVE "${package_generated_file}")
			file(REMOVE "${package_cmake_generated_file}")

		# me lo he descargdo y solo es descomprimirlo
		elseif(EXISTS "${package_uncompressed_file}")

			# 10. lo descomprimo cacheado
			execute_process(
				COMMAND "${CMAKE_COMMAND}" -E tar zxf "${package_uncompressed_file}"
				WORKING_DIRECTORY "${CMAKE_PREFIX_PATH}/"
				RESULT_VARIABLE uncompress_result)
			if(uncompress_result)
				message(FATAL_ERROR "Extracting ${package_uncompressed_file} failed! Error ${uncompress_result}")
			endif()
			file(REMOVE "${package_uncompressed_file}")
		endif()
	endif()

	# 12. hacer find_package tradicional, ahora que tenemos los ficheros de cmake
	if(${PACKAGE_MODE} STREQUAL "EXACT")
		# message("-- using ${PACKAGE} in EXACT")
		find_package(${PACKAGE} ${VERSION} EXACT REQUIRED)
	else()
		# message("-- using ${PACKAGE} in COMPATIBLE")
		find_package(${PACKAGE} ${VERSION} REQUIRED)
	endif()

	# generate json
	execute_process(
		COMMAND python ${ARTIFACTS_PATH}/save_package.py --name=${PACKAGE} --depends=${DEPENDS_PATHFILE} --version=${VERSION}
		WORKING_DIRECTORY "${ARTIFACTS_PATH}"
		OUTPUT_VARIABLE RESULT_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
	if(RESULT_VERSION)
		message("error saving ${PACKAGE}:${VERSION} in ${DEPENDS_PATH}")
	endif()

	# 13 add includes
	string(TOUPPER "${PACKAGE}" PACKAGE_UPPER)
	foreach(INCLUDE_DIR ${${PACKAGE_UPPER}_INCLUDE_DIRS})
		list(APPEND CMAKI_INCLUDE_DIRS "${INCLUDE_DIR}")
	endforeach()

	# 14. add libdirs
	foreach(LIB_DIR ${${PACKAGE_UPPER}_LIBRARIES})
		list(APPEND CMAKI_LIBRARIES "${LIB_DIR}")
	endforeach()

	# 15. add vers specific
	set(${PACKAGE_UPPER}_INCLUDE_DIRS "${${PACKAGE_UPPER}_INCLUDE_DIRS}" PARENT_SCOPE)
	set(${PACKAGE_UPPER}_LIBRARIES "${${PACKAGE_UPPER}_LIBRARIES}" PARENT_SCOPE)

	# 16. add vars globals
	set(CMAKI_INCLUDE_DIRS "${CMAKI_INCLUDE_DIRS}" PARENT_SCOPE)
	set(CMAKI_LIBRARIES "${CMAKI_LIBRARIES}" PARENT_SCOPE)

endfunction()

macro(cmaki_package_version_check)
	# llamar a check_remote_version
	# dando el nombre recibo la version
	execute_process(
		COMMAND python ${ARTIFACTS_PATH}/check_remote_version.py --artifacts=${CMAKE_PREFIX_PATH} --platform=${CMAKI_PLATFORM} --name=${PACKAGE_FIND_NAME} --version=${PACKAGE_FIND_VERSION}
		WORKING_DIRECTORY "${ARTIFACTS_PATH}"
		OUTPUT_VARIABLE RESULT_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
	list(GET RESULT_VERSION 0 RESULT)
	list(GET RESULT_VERSION 1 NAME)
	list(GET RESULT_VERSION 2 VERSION)
	###################################
	set(PACKAGE_VERSION_${RESULT} 1)
	set(${NAME}_VERSION ${VERSION})
endmacro()

function(cmaki_install_3rdparty)
	foreach(CMAKI_3RDPARTY_TARGET ${ARGV})
		foreach(CMAKI_BUILD_TYPE ${CMAKE_CONFIGURATION_TYPES} ${CMAKE_BUILD_TYPE})
			string(TOUPPER "${CMAKI_BUILD_TYPE}" CMAKI_BUILD_TYPE_UPPER)
			get_target_property(CMAKI_3RDPARTY_TARGET_TYPE ${CMAKI_3RDPARTY_TARGET} TYPE)
			if(${CMAKI_3RDPARTY_TARGET_TYPE} STREQUAL "SHARED_LIBRARY")
				get_target_property(CMAKI_3RDPARTY_TARGET_LOCATION ${CMAKI_3RDPARTY_TARGET} IMPORTED_LOCATION_${CMAKI_BUILD_TYPE_UPPER})
				get_target_property(CMAKI_3RDPARTY_TARGET_SONAME ${CMAKI_3RDPARTY_TARGET} IMPORTED_SONAME_${CMAKI_BUILD_TYPE_UPPER})
				get_target_property(CMAKI_3RDPARTY_TARGET_PDB ${CMAKI_3RDPARTY_TARGET} IMPORTED_PDB_${CMAKI_BUILD_TYPE_UPPER})
				if(CMAKI_3RDPARTY_TARGET_SONAME)
					get_filename_component(CMAKI_3RDPARTY_TARGET_LOCATION_PATH "${CMAKI_3RDPARTY_TARGET_LOCATION}" PATH)
					set(CMAKI_3RDPARTY_TARGET_LOCATION "${CMAKI_3RDPARTY_TARGET_LOCATION_PATH}/${CMAKI_3RDPARTY_TARGET_SONAME}")
				endif()
				get_filename_component(CMAKI_3RDPARTY_TARGET_INSTALLED_NAME "${CMAKI_3RDPARTY_TARGET_LOCATION}" NAME)
				get_filename_component(CMAKI_3RDPARTY_TARGET_LOCATION "${CMAKI_3RDPARTY_TARGET_LOCATION}" REALPATH)
				install(PROGRAMS ${CMAKI_3RDPARTY_TARGET_LOCATION}
					DESTINATION ${CMAKI_BUILD_TYPE}
					CONFIGURATIONS ${CMAKI_BUILD_TYPE}
					RENAME ${CMAKI_3RDPARTY_TARGET_INSTALLED_NAME})
				if((NOT UNIX) AND EXISTS ${CMAKI_3RDPARTY_TARGET_PDB})
					get_filename_component(CMAKI_3RDPARTY_TARGET_PDB_NAME "${CMAKI_3RDPARTY_TARGET_PDB}" NAME)
					install(PROGRAMS ${CMAKI_3RDPARTY_TARGET_PDB}
						DESTINATION ${CMAKI_BUILD_TYPE}
						CONFIGURATIONS ${CMAKI_BUILD_TYPE}
						RENAME ${CMAKI_3RDPARTY_TARGET_PDB_NAME})
				endif()
			endif()
		endforeach()
	endforeach()
endfunction()

function(cmaki_download_file THE_URL INTO_FILE)
	set(COPY_SUCCESFUL FALSE PARENT_SCOPE)
	file(DOWNLOAD ${THE_URL} ${INTO_FILE} STATUS RET)
	list(GET RET 0 RET_CODE)
	if(RET_CODE EQUAL 0)
		set(COPY_SUCCESFUL TRUE PARENT_SCOPE)
	else()
		set(COPY_SUCCESFUL FALSE PARENT_SCOPE)
	endif()
endfunction()

macro(cmaki_download_package)
	# Base URL for packages.
	if(NOT DEFINED CMAKI_REPOSITORY)
		# MESSAGE(FATAL_ERROR "CMAKI_REPOSITORY: is not defined")
		set(CMAKI_REPOSITORY "http://artifacts.myftp.biz:8080")
	endif()
	get_filename_component(package_dir "${CMAKE_CURRENT_LIST_FILE}" PATH)
	# ${package_name} en realidad es paquete + version (asyncply-0.0.0.0)
	get_filename_component(package_name "${package_dir}" NAME)
	set(package_filename ${package_name}-${CMAKI_PLATFORM}.tar.gz)
	set(http_package_filename ${CMAKI_REPOSITORY}/download.php?file=${package_filename})

	# URL implicita
	# strip implicito

	set(depends_dir "${DEPENDS_PATH}")
	get_filename_component(depends_dir "${depends_dir}" ABSOLUTE)
	set(package_compessed "${depends_dir}/${package_name}.tar.gz")
	set(package_uncompressed_dir "${depends_dir}/${package_name}.tmp")
	set(package_marker "${depends_dir}/${package_name}/${CMAKI_PLATFORM}.cache")
	set(package_compressed_md5 "${package_dir}/${package_name}-${CMAKI_PLATFORM}.md5")
	set(strip_compressed "${package_name}")
	set(_MY_DIR "${package_dir}")
	set(_DIR "${depends_dir}/${strip_compressed}")

	if(NOT EXISTS "${package_marker}")
		# TODO: avoid doble download
		file(REMOVE "${package_compessed}")
		if(EXISTS "${package_compressed_md5}")
			file(READ "${package_compressed_md5}" md5sum )
			string(REGEX MATCH "[0-9a-fA-F]*" md5sum "${md5sum}")
			# TODO: use md5sum
			# cmaki_download_file("${http_package_filename}" "${package_compessed}" "${md5sum}" )
			message("downloading ${http_package_filename}")
			cmaki_download_file("${http_package_filename}" "${package_compessed}")
			if(NOT "${COPY_SUCCESFUL}")
				file(REMOVE "${package_compessed}")
				message(FATAL_ERROR "Error downloading ${http_package_filename}")
			endif()
		else()
			MESSAGE("Checksum for ${package_name}-${CMAKI_PLATFORM}.tar.gz not found. Rejecting to download an untrustworthy file.")
			file(REMOVE_RECURSE "${package_dir}")
			file(REMOVE_RECURSE "${_DIR}")
		endif()
	endif()

	if(EXISTS "${package_compessed}")
		file(MAKE_DIRECTORY "${package_uncompressed_dir}")
		message("Extracting ${package_compessed} into ${package_uncompressed_dir}...")
		execute_process(
			COMMAND "${CMAKE_COMMAND}" -E tar zxf "${package_compessed}"
			WORKING_DIRECTORY "${package_uncompressed_dir}"
			RESULT_VARIABLE uncompress_result)
		if(uncompress_result)
			message(FATAL_ERROR "Extracting ${package_compessed} failed! Error ${uncompress_result}")
		endif()
		file(COPY "${package_uncompressed_dir}/${strip_compressed}" DESTINATION "${depends_dir}")
		file(REMOVE "${package_compessed}")
		file(REMOVE_RECURSE "${package_uncompressed_dir}")
		file(WRITE "${package_marker}" "")
	endif()

endmacro()

function(cmaki2_executable)
	cmaki_parse_parameters(${ARGV})
	set(_EXECUTABLE_NAME ${_MAIN_NAME})
	source_group( "Source Files" FILES ${_SOURCES} )
	common_flags()
	common_linking(${_EXECUTABLE_NAME})
	include_directories(${CMAKE_SOURCE_DIR})
	include_directories(node_modules)
	foreach(INCLUDE_DIR ${CMAKI_INCLUDE_DIRS})
		include_directories(${INCLUDE_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		if(${CMAKE_SYSTEM_NAME} MATCHES "Android")
			message("-- android no need extra linkage for pthreads")
		else()
			add_compile_options(-pthread)
		endif()
	endif()
	if(WIN32)
		ADD_EXECUTABLE(${_EXECUTABLE_NAME} WIN32 ${_SOURCES})
	else()
		ADD_EXECUTABLE(${_EXECUTABLE_NAME} ${_SOURCES})
	endif()
	target_link_libraries(${_EXECUTABLE_NAME} ${_DEPENDS})
	# echo_targets(${_EXECUTABLE_NAME})
	foreach(LIB_DIR ${CMAKI_LIBRARIES})
		target_link_libraries(${_EXECUTABLE_NAME} ${LIB_DIR})
		cmaki_install_3rdparty(${LIB_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		if(${CMAKE_SYSTEM_NAME} MATCHES "Android")
			message("-- android no need extra linkage for pthreads")
		else()
			target_link_libraries(${_EXECUTABLE_NAME} -lpthread)
		endif()
	endif()
	foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(    TARGETS ${_EXECUTABLE_NAME}
					DESTINATION ${BUILD_TYPE}/${_SUFFIX_DESTINATION}
					CONFIGURATIONS ${BUILD_TYPE})
	endforeach()
	generate_vcxproj_user(${_EXECUTABLE_NAME})

endfunction()

function(cmaki2_library)
	cmaki_parse_parameters(${ARGV})
	set(_LIBRARY_NAME ${_MAIN_NAME})
	source_group( "Source Files" FILES ${_SOURCES} )
	common_flags()
	common_linking(${_LIBRARY_NAME})
	include_directories(${CMAKE_SOURCE_DIR})
	include_directories(node_modules)
	foreach(INCLUDE_DIR ${CMAKI_INCLUDE_DIRS})
		include_directories(${INCLUDE_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		if(${CMAKE_SYSTEM_NAME} MATCHES "Android")
			message("-- android no need extra linkage for pthreads")
		else()
			add_compile_options(-pthread)
		endif()
	endif()
	add_library(${_LIBRARY_NAME} SHARED ${_SOURCES})
	target_link_libraries(${_LIBRARY_NAME} ${_DEPENDS})
	# echo_targets(${_LIBRARY_NAME})
	foreach(LIB_DIR ${CMAKI_LIBRARIES})
		target_link_libraries(${_LIBRARY_NAME} ${LIB_DIR})
		cmaki_install_3rdparty(${LIB_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		if(${CMAKE_SYSTEM_NAME} MATCHES "Android")
			message("-- android no need extra linkage for pthreads")
		else()
			target_link_libraries(${_LIBRARY_NAME} -lpthread)
		endif()
	endif()
	foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(	TARGETS ${_LIBRARY_NAME}
					DESTINATION ${BUILD_TYPE}/${_SUFFIX_DESTINATION}
					CONFIGURATIONS ${BUILD_TYPE})
	endforeach()

endfunction()

function(cmaki2_static_library)
	cmaki_parse_parameters(${ARGV})
	set(_LIBRARY_NAME ${_MAIN_NAME})
	source_group( "Source Files" FILES ${_SOURCES} )
	common_flags()
	common_linking(${_LIBRARY_NAME})
	add_definitions(-D${_LIBRARY_NAME}_STATIC)
	include_directories(${CMAKE_SOURCE_DIR})
	include_directories(node_modules)
	foreach(INCLUDE_DIR ${CMAKI_INCLUDE_DIRS})
		include_directories(${INCLUDE_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		if(${CMAKE_SYSTEM_NAME} MATCHES "Android")
			message("-- android no need extra linkage for pthreads")
		else()
			add_compile_options(-pthread)
		endif()
	endif()
	add_library(${_LIBRARY_NAME} STATIC ${_SOURCES})
	target_link_libraries(${_LIBRARY_NAME} ${_DEPENDS})
	# echo_targets(${_LIBRARY_NAME})
	foreach(LIB_DIR ${CMAKI_LIBRARIES})
		target_link_libraries(${_LIBRARY_NAME} ${LIB_DIR})
		cmaki_install_3rdparty(${LIB_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		if(${CMAKE_SYSTEM_NAME} MATCHES "Android")
			message("-- android no need extra linkage for pthreads")
		else()
			target_link_libraries(${_LIBRARY_NAME} -lpthread)
		endif()
	endif()
	foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(	TARGETS ${_LIBRARY_NAME}
					DESTINATION ${BUILD_TYPE}/${_SUFFIX_DESTINATION}
					CONFIGURATIONS ${BUILD_TYPE})
	endforeach()
endfunction()

function(cmaki2_test)
	cmaki_parse_parameters(${ARGV})
	set(_TEST_NAME ${_MAIN_NAME})
	common_flags()
	common_linking(${_TEST_NAME}_exe)
	include_directories(node_modules)
	foreach(INCLUDE_DIR ${CMAKI_INCLUDE_DIRS})
		include_directories(${INCLUDE_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		if(${CMAKE_SYSTEM_NAME} MATCHES "Android")
			message("-- android no need extra linkage for pthreads")
		else()
			add_compile_options(-pthread)
		endif()
	endif()
	add_executable(${_TEST_NAME}_exe ${_SOURCES})
	target_link_libraries(${_TEST_NAME}_exe ${_DEPENDS})
	foreach(LIB_DIR ${CMAKI_LIBRARIES})
		target_link_libraries(${_TEST_NAME}_exe ${LIB_DIR})
		cmaki_install_3rdparty(${LIB_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		if(${CMAKE_SYSTEM_NAME} MATCHES "Android")
			message("-- android no need extra linkage for pthreads")
		else()
			target_link_libraries(${_TEST_NAME}_exe -lpthread)
		endif()
	endif()
	foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(  	TARGETS ${_TEST_NAME}_exe
				DESTINATION ${BUILD_TYPE}/${_SUFFIX_DESTINATION}
				CONFIGURATIONS ${BUILD_TYPE})
		if (DEFINED TESTS_VALGRIND AND (TESTS_VALGRIND STREQUAL "TRUE") AND (CMAKE_CXX_COMPILER_ID STREQUAL "Clang") AND (CMAKE_BUILD_TYPE STREQUAL "Release"))
			find_program(VALGRIND "valgrind")
			if(VALGRIND)
				add_test(
					NAME ${_TEST_NAME}_memcheck
					COMMAND "${VALGRIND}" --tool=memcheck --leak-check=yes --show-reachable=yes --num-callers=20 --track-fds=yes $<TARGET_FILE:${_TEST_NAME}_exe> --gmock_verbose=error
					WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${BUILD_TYPE}
					CONFIGURATIONS ${BUILD_TYPE}
					)
				add_test(
					NAME ${_TEST_NAME}_cachegrind
					COMMAND "${VALGRIND}" --tool=cachegrind $<TARGET_FILE:${_TEST_NAME}_exe> --gmock_verbose=error
					WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${BUILD_TYPE}
					CONFIGURATIONS ${BUILD_TYPE}
					)
				add_test(
					NAME ${_TEST_NAME}_helgrind
					COMMAND "${VALGRIND}" --tool=helgrind $<TARGET_FILE:${_TEST_NAME}_exe> --gmock_verbose=error
					WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${BUILD_TYPE}
					CONFIGURATIONS ${BUILD_TYPE}
					)
				add_test(
					NAME ${_TEST_NAME}_callgrind
					COMMAND "${VALGRIND}" --tool=callgrind $<TARGET_FILE:${_TEST_NAME}_exe> --gmock_verbose=error
					WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${BUILD_TYPE}
					CONFIGURATIONS ${BUILD_TYPE}
					)
				add_test(
					NAME ${_TEST_NAME}_drd
					COMMAND "${VALGRIND}" --tool=drd --read-var-info=yes $<TARGET_FILE:${_TEST_NAME}_exe> --gmock_verbose=error
					WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${BUILD_TYPE}
					CONFIGURATIONS ${BUILD_TYPE}
					)
			else()
				message(FATAL_ERROR "no valgrind detected")
			endif()
		endif()
		if(DEFINED ENV{CMAKI_EMULATOR})
			add_test(
				NAME ${_TEST_NAME}_test
				COMMAND "$ENV{CMAKI_EMULATOR}" $<TARGET_FILE:${_TEST_NAME}_exe> --gmock_verbose=error
				WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${BUILD_TYPE}
				CONFIGURATIONS ${BUILD_TYPE})
		else()
			add_test(
				NAME ${_TEST_NAME}_test
				COMMAND $<TARGET_FILE:${_TEST_NAME}_exe> --gmock_verbose=error
				WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${BUILD_TYPE}
				CONFIGURATIONS ${BUILD_TYPE})
		endif()
	endforeach()
	generate_vcxproj_user(${_TEST_NAME})

endfunction()

macro(cmaki2_gtest)
	cmaki_find_package(google-gmock)
	cmaki2_test(${ARGV})
endmacro()

macro(cmaki_python_library)
	cmaki_find_package(python)
	cmaki_find_package(boost-python)
	cmaki2_library(${ARGV} PTHREADS)
	cmaki_parse_parameters(${ARGV})
	set_target_properties(${_MAIN_NAME} PROPERTIES PREFIX "")
	foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(	TARGETS ${_MAIN_NAME}
				DESTINATION ${BUILD_TYPE}/lib/python3.5/lib-dynload
				CONFIGURATIONS ${BUILD_TYPE})
	endforeach()
endmacro()

macro(cmaki_boost_python_test)
	cmaki_find_package(python)
	cmaki_find_package(boost-python)
	cmaki2_gtest(${ARGV} PTHREADS)
	cmaki_parse_parameters(${ARGV})
	set_tests_properties(${_MAIN_NAME}_test PROPERTIES ENVIRONMENT "PYTHONPATH=${CMAKE_INSTALL_PREFIX}/${CMAKE_BUILD_TYPE}")
endmacro()

macro(cmaki_python_test)
	cmaki_find_package(python)
	cmaki_parse_parameters(${ARGV})
	add_test(	NAME ${_MAIN_NAME}_test
			COMMAND ./bin/python3 ${_SOURCES}
			WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${CMAKE_BUILD_TYPE})
	set_tests_properties(${_MAIN_NAME}_test PROPERTIES ENVIRONMENT "LD_LIBRARY_PATH=${CMAKE_INSTALL_PREFIX}/${CMAKE_BUILD_TYPE}")
endmacro()

macro(cmaki_python_install)
	cmaki_find_package(python)
	cmaki_find_package(boost-python)
	get_filename_component(PYTHON3_DIR ${PYTHON3_EXECUTABLE} DIRECTORY)
	get_filename_component(PYTHON3_PARENT_DIR ${PYTHON3_DIR} DIRECTORY)
	cmaki_install_inside_dir(${PYTHON3_PARENT_DIR})
endmacro()
