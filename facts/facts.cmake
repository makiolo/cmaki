cmake_minimum_required(VERSION 2.8)
cmake_policy(SET CMP0011 NEW)
cmake_policy(SET CMP0045 OLD)

IF(NOT DEFINED CMAKI_PATH)
	set(CMAKI_PATH ${CMAKE_MODULE_PATH})
ENDIF()

IF(NOT DEFINED DEPENDS_PATH)
	set(DEPENDS_PATH ${CMAKI_PATH}/../depends)
ENDIF()

IF(NOT DEFINED CMAKE_PREFIX_PATH)
	set(CMAKE_PREFIX_PATH ${DEPENDS_PATH}/cmakefiles)
ENDIF()

IF(NOT DEFINED ARTIFACTS_PATH)
	set(ARTIFACTS_PATH ${CMAKI_PATH}/../cmaki_generator)
ENDIF()

IF(NOT DEFINED DEPENDS_PATHFILE)
	# rename to ".cmaki.yml" ?
	set(DEPENDS_PATHFILE ${CMAKI_PATH}/../depends.json)
ENDIF()

if(DEFINED CMAKI_DEBUG)
	MESSAGE("CMAKI_PATH = ${CMAKI_PATH}")
	MESSAGE("DEPENDS_PATH = ${DEPENDS_PATH}")
	MESSAGE("CMAKE_PREFIX_PATH = ${CMAKE_PREFIX_PATH}")
	MESSAGE("ARTIFACTS_PATH = ${ARTIFACTS_PATH}")
	MESSAGE("DEPENDS_PATHFILE = ${DEPENDS_PATHFILE}")
	MESSAGE(FATAL_ERROR)
endif()

IF(WIN32)
	if(MSVC14)
		set(MSVC_NAME_LOWER "vc140")
		set(MSVC_NAME_UPPER "VC140")
	elseif(MSVC13)
		set(MSVC_NAME_LOWER "vc130")
		set(MSVC_NAME_UPPER "VC130")
	elseif(MSVC12)
		set(MSVC_NAME_LOWER "vc120")
		set(MSVC_NAME_UPPER "VC120")
	elseif(MSVC11)
		set(MSVC_NAME_LOWER "vc110")
		set(MSVC_NAME_UPPER "VC110")
	elseif(MSVC10)
		set(MSVC_NAME_LOWER "vc100")
		set(MSVC_NAME_UPPER "VC100")
	elseif(MSVC9)
		set(MSVC_NAME_LOWER "vc90")
		set(MSVC_NAME_UPPER "VC90")
	else(MSVC8)
		set(MSVC_NAME_LOWER "vc80")
		set(MSVC_NAME_UPPER "VC80")
	endif()
	SET(CMAKI_COMPILER "${MSVC_NAME_UPPER}")
ELSE()
	SET(compiler "")
	get_filename_component(compiler ${CMAKE_CXX_COMPILER} NAME)
	SET(CMAKI_COMPILER "${compiler}")
ENDIF()

IF(WIN32)
	if(CMAKE_CL_64)
		set(CMAKI_PLATFORM "win64")
	else(CMAKE_CL_64)
		set(CMAKI_PLATFORM "win32")
	endif(CMAKE_CL_64)
ELSE()
	execute_process(
		COMMAND sh detect_operative_system.sh
		WORKING_DIRECTORY "${CMAKI_PATH}/ci"
		OUTPUT_VARIABLE RESULT_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
	set(CMAKI_PLATFORM "${RESULT_VERSION}")
ENDIF()

function(cmaki_find_package PACKAGE)

	IF(NOT DEFINED CMAKI_REPOSITORY)
		MESSAGE(FATAL_ERROR "CMAKI_REPOSITORY: is not defined")
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
	if(NOT EXISTS "${depends_package}" OR "${NO_USE_CACHE_LOCAL}")
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
		# 4. descargo el fichero que se supone tienes los ficheros cmake
		if(NOT "${NO_USE_CACHE_REMOTE}")
			message("Downloading ${http_package_cmake_filename} ...")
			cmaki_download_file("${http_package_cmake_filename}" "${package_uncompressed_file}")
		endif()
		# Si no puede descargar el artefacto ya hecho (es que necesito compilarlo y subirlo)
		if(NOT "${COPY_SUCCESFUL}" OR "${NO_USE_CACHE_REMOTE}")

			file(REMOVE_RECURSE "${depends_bin_package}")
			file(REMOVE_RECURSE "${depends_package}")
			file(REMOVE "${package_uncompressed_file}")

			# 5. compilo y genera el paquete en local
			message("Generating artifact ${PACKAGE} ...")
			execute_process(
				COMMAND python ${ARTIFACTS_PATH}/build.py ${PACKAGE} --depends=${DEPENDS_PATHFILE} --cmakefiles=${CMAKI_PATH} --prefix=${CMAKE_PREFIX_PATH} --third-party-dir=${CMAKE_PREFIX_PATH} --server=${CMAKI_REPOSITORY} --no-upload -o
				WORKING_DIRECTORY "${ARTIFACTS_PATH}"
				RESULT_VARIABLE artifacts_result
				)
			if(artifacts_result)
				message(FATAL_ERROR "can't create artifact ${PACKAGE}")
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

	# 11. Guardar nuestra version en uso
	execute_process(
		COMMAND python ${ARTIFACTS_PATH}/save_package.py --name=${PACKAGE} --version=${VERSION} --depends=${DEPENDS_PATHFILE}
		WORKING_DIRECTORY "${ARTIFACTS_PATH}"
		RESULT_VARIABLE artifacts_result)
	if(artifacts_result)
		message(FATAL_ERROR "can't save package version: ${PACKAGE} ${VERSION}")
	endif()

	# 12. hacer find_package tradicional, ahora que tenemos los ficheros de cmake
	if(${PACKAGE_MODE} STREQUAL "EXACT")
		# message("-- using ${PACKAGE} in EXACT")
		find_package(${PACKAGE} ${VERSION} EXACT REQUIRED)
	else()
		# message("-- using ${PACKAGE} in COMPATIBLE")
		find_package(${PACKAGE} ${VERSION} REQUIRED)
	endif()

	# 13 aÃ±adir los includes
	string(TOUPPER "${PACKAGE}" PACKAGE_UPPER)
	foreach(INCLUDE_DIR ${${PACKAGE_UPPER}_INCLUDE_DIRS})
		list(APPEND CMAKI_INCLUDE_DIRS "${INCLUDE_DIR}")
	endforeach()

	# 14. añadir los libdir
	foreach(LIB_DIR ${${PACKAGE_UPPER}_LIBRARIES})
		list(APPEND CMAKI_LIBRARIES "${LIB_DIR}")
	endforeach()

	# 15. aÃ±adir variables especificas
	set(${PACKAGE_UPPER}_INCLUDE_DIRS "${${PACKAGE_UPPER}_INCLUDE_DIRS}" PARENT_SCOPE)
	set(${PACKAGE_UPPER}_LIBRARIES "${${PACKAGE_UPPER}_LIBRARIES}" PARENT_SCOPE)

	# 16. aÃ±aadir variabes generales
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
	IF(NOT DEFINED CMAKI_REPOSITORY)
		MESSAGE(FATAL_ERROR "CMAKI_REPOSITORY: is not defined")
	ENDIF()
	get_filename_component(package_dir "${CMAKE_CURRENT_LIST_FILE}" PATH)
	# ${package_name} en realidad es paquete + version (asyncply-0.0.0.0)
	get_filename_component(package_name "${package_dir}" NAME)
	set(package_cmake_filename ${package_name}-${CMAKI_PLATFORM}.tar.gz)
	set(http_package_cmake_filename ${CMAKI_REPOSITORY}/download.php?file=${package_cmake_filename})

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
		file(REMOVE "${package_compessed}")
		if(EXISTS "${package_compressed_md5}")
			file(READ "${package_compressed_md5}" md5sum )
			string(REGEX MATCH "[0-9a-fA-F]*" md5sum "${md5sum}")
			# TODO: use md5sum
			# cmaki_download_file("${http_package_cmake_filename}" "${package_compessed}" "${md5sum}" )
			cmaki_download_file("${http_package_cmake_filename}" "${package_compessed}")
			if(NOT "${COPY_SUCCESFUL}")
				file(REMOVE "${package_compessed}")
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
	include_directories(${CMAKE_SOURCE_DIR})
	foreach(INCLUDE_DIR ${CMAKI_INCLUDE_DIRS})
		include_directories(${INCLUDE_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		add_compile_options(-pthread)
	endif()
	if(WIN32)
		ADD_EXECUTABLE(${_EXECUTABLE_NAME} WIN32 ${_SOURCES})
	else()
		ADD_EXECUTABLE(${_EXECUTABLE_NAME} ${_SOURCES})
	endif()
	target_link_libraries(${_EXECUTABLE_NAME} ${_DEPENDS})
	foreach(LIB_DIR ${CMAKI_LIBRARIES})
		target_link_libraries(${_EXECUTABLE_NAME} ${LIB_DIR})
		cmaki_install_3rdparty(${LIB_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		target_link_libraries(${_EXECUTABLE_NAME} -lpthread)
	endif()
	foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(    TARGETS ${_EXECUTABLE_NAME}
					DESTINATION ${BUILD_TYPE}
					CONFIGURATIONS ${BUILD_TYPE})
	endforeach()
	generate_vcxproj_user(${_EXECUTABLE_NAME})

endfunction()

function(cmaki2_library)
	cmaki_parse_parameters(${ARGV})
	set(_LIBRARY_NAME ${_MAIN_NAME})
	source_group( "Source Files" FILES ${_SOURCES} )
	common_flags()
	include_directories(${CMAKE_SOURCE_DIR})
	foreach(INCLUDE_DIR ${CMAKI_INCLUDE_DIRS})
		include_directories(${INCLUDE_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		add_compile_options(-pthread)
	endif()
	add_library(${_LIBRARY_NAME} SHARED ${_SOURCES})
	target_link_libraries(${_LIBRARY_NAME} ${_DEPENDS})
	foreach(LIB_DIR ${CMAKI_LIBRARIES})
		target_link_libraries(${_LIBRARY_NAME} ${LIB_DIR})
		cmaki_install_3rdparty(${LIB_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		target_link_libraries(${_LIBRARY_NAME} -lpthread)
	endif()
	foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(	TARGETS ${_LIBRARY_NAME}
					DESTINATION ${BUILD_TYPE}
					CONFIGURATIONS ${BUILD_TYPE})
	endforeach()

endfunction()

function(cmaki2_static_library)
	cmaki_parse_parameters(${ARGV})
	set(_LIBRARY_NAME ${_MAIN_NAME})
	source_group( "Source Files" FILES ${_SOURCES} )
	common_flags()
	include_directories(${CMAKE_SOURCE_DIR})
	foreach(INCLUDE_DIR ${CMAKI_INCLUDE_DIRS})
		include_directories(${INCLUDE_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		add_compile_options(-pthread)
	endif()
	add_library(${_LIBRARY_NAME} STATIC ${_SOURCES})
	target_link_libraries(${_LIBRARY_NAME} ${_DEPENDS})
	foreach(LIB_DIR ${CMAKI_LIBRARIES})
		target_link_libraries(${_LIBRARY_NAME} ${LIB_DIR})
		cmaki_install_3rdparty(${LIB_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		target_link_libraries(${_LIBRARY_NAME} -lpthread)
	endif()
	foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(	TARGETS ${_LIBRARY_NAME}
					DESTINATION ${BUILD_TYPE}
					CONFIGURATIONS ${BUILD_TYPE})
	endforeach()

endfunction()

function(cmaki2_test)
	cmaki_parse_parameters(${ARGV})
	set(_TEST_NAME ${_MAIN_NAME})
	foreach(INCLUDE_DIR ${CMAKI_INCLUDE_DIRS})
		include_directories(${INCLUDE_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		add_compile_options(-pthread)
	endif()
	add_executable(${_TEST_NAME}_exe ${_SOURCES})
	target_link_libraries(${_TEST_NAME}_exe ${_DEPENDS})
	foreach(LIB_DIR ${CMAKI_LIBRARIES})
		target_link_libraries(${_TEST_NAME}_exe ${LIB_DIR})
		cmaki_install_3rdparty(${LIB_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		target_link_libraries(${_TEST_NAME}_exe -lpthread)
	endif()
	foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(    TARGETS ${_TEST_NAME}_exe
					DESTINATION ${BUILD_TYPE}
					CONFIGURATIONS ${BUILD_TYPE})
	endforeach()
	add_test(
		NAME ${_TEST_NAME}_exe
		COMMAND ${_TEST_NAME}_exe --gtest_repeat=5 --gtest_break_on_failure --gtest_shuffle
		WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${CMAKE_BUILD_TYPE})
	generate_vcxproj_user(${_TEST_NAME})

endfunction()

macro(cmaki2_gtest)
	cmaki_find_package(google-gtest)
	cmaki_find_package(google-gmock)
	cmaki2_test(${ARGV})
endmacro()
