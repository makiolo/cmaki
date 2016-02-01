cmake_minimum_required(VERSION 2.8)
cmake_policy(SET CMP0011 NEW)
cmake_policy(SET CMP0045 OLD)

IF(NOT DEFINED CMAKE_PREFIX_PATH)
	set(CMAKE_PREFIX_PATH ${CMAKI_PATH}/../depends/cmakefiles)
ENDIF()

IF(NOT DEFINED ARTIFACTS_PATH)
	set(ARTIFACTS_PATH ${CMAKE_CURRENT_SOURCE_DIR}/..)
ENDIF()

IF(NOT DEFINED CMAKI_PATH)
	set(CMAKI_PATH ${CMAKE_PREFIX_PATH}/..)
ENDIF()

MESSAGE("CMAKI_PATH = ${CMAKI_PATH}")
MESSAGE("ARTIFACTS_PATH = ${ARTIFACTS_PATH}")
MESSAGE("CMAKE_PREFIX_PATH = ${CMAKE_PREFIX_PATH}")

set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/bin)
set(PACKAGE_BASE_URL "http://localhost/artifacts")

IF(WIN32)
	if(MSVC12)
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
MESSAGE("-- compiler detected: ${CMAKI_COMPILER}")

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
MESSAGE("-- platform detected: ${CMAKI_PLATFORM}")

function(cmaki_find_package PACKAGE)

	IF(NOT DEFINED PACKAGE_BASE_URL)
		MESSAGE(FATAL_ERROR "PACKAGE_BASE_URL: is not defined")
	ENDIF()

	#######################################################
	# llamar a check_remote_version
	# dando el nombre recibo la version
	execute_process(
		COMMAND python ${ARTIFACTS_PATH}/check_remote_version.py --server=${PACKAGE_BASE_URL} --artifacts=${CMAKE_PREFIX_PATH} --platform=${CMAKI_PLATFORM} --name=${PACKAGE}
		WORKING_DIRECTORY "${ARTIFACTS_PATH}"
		OUTPUT_VARIABLE RESULT_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
	#MESSAGE("RESULT_VERSION1 = ${RESULT_VERSION}")
	list(GET RESULT_VERSION 0 PACKAGE_MODE)
	list(GET RESULT_VERSION 1 PACKAGE_NAME)
	list(GET RESULT_VERSION 2 VERSION)
	#######################################################

	set(FORCE FALSE)

	# si no tengo los ficheros de cmake del paquete
	set(depends_package ${CMAKE_PREFIX_PATH}/${PACKAGE}-${VERSION})
	if((NOT EXISTS "${depends_package}") OR ${FORCE})
		# pido un paquete, en funcion de:
		#		- paquete
		#		- version
		#		- plataforma
		#		- modo (COMPATIBLE / EXACT)
		# Recibo el que mejor se adapta a mis especificaciones
		# Otra opcion es enviar todos los ficheros de cmake de todas las versiones
		set(package_uncompressed_file "${CMAKE_PREFIX_PATH}/${PACKAGE}.tmp")
		set(package_cmake_filename ${PACKAGE}-${VERSION}-${CMAKI_PLATFORM}-cmake.tar.gz)
		set(http_package_cmake_filename ${PACKAGE_BASE_URL}/download.php?file=${package_cmake_filename})
		cmaki_download_file("${http_package_cmake_filename}" "${package_uncompressed_file}")
		# Si no puede descargar el artefacto (es posible no tener la version definida)
		if((NOT "${COPY_SUCCESFUL}") OR ${FORCE})

			file(REMOVE "${package_uncompressed_file}")
			# generar artefactos de una version determinada

			execute_process(
				COMMAND python ${ARTIFACTS_PATH}/build.py ${PACKAGE} --depends=${CMAKI_PATH}/../depends.yml --cmakefiles=${CMAKI_PATH} --prefix=${CMAKE_PREFIX_PATH} --third-party-dir=${CMAKE_PREFIX_PATH} -o -d
				WORKING_DIRECTORY "${ARTIFACTS_PATH}"
				RESULT_VARIABLE artifacts_result
				)
			if(artifacts_result)
				message(FATAL_ERROR "can't create artifact ${PACKAGE}")
			endif()

			#######################################################
			# llamar a check_remote_version
			# dando el nombre recibo la version
			execute_process(
				COMMAND python ${ARTIFACTS_PATH}/check_remote_version.py --server=${PACKAGE_BASE_URL} --artifacts=${CMAKE_PREFIX_PATH} --platform=${CMAKI_PLATFORM} --name=${PACKAGE}
				WORKING_DIRECTORY "${ARTIFACTS_PATH}"
				OUTPUT_VARIABLE RESULT_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
			#MESSAGE("RESULT_VERSION2 = ${RESULT_VERSION}")
			list(GET RESULT_VERSION 0 PACKAGE_MODE)
			list(GET RESULT_VERSION 1 PACKAGE_NAME)
			list(GET RESULT_VERSION 2 VERSION)
			#######################################################

			# 2. Opcionalmente subo el artefacto
			set(package_filename ${PACKAGE}-${VERSION}-${CMAKI_PLATFORM}.tar.gz)
			set(package_cmake_filename ${PACKAGE}-${VERSION}-${CMAKI_PLATFORM}-cmake.tar.gz)
			set(package_generated_file ${CMAKE_PREFIX_PATH}/${package_filename})
			set(package_cmake_generated_file ${CMAKE_PREFIX_PATH}/${package_cmake_filename})
			execute_process(
				COMMAND python ${ARTIFACTS_PATH}/upload_package.py --url=${PACKAGE_BASE_URL}/upload.php --filename=${package_generated_file}
				WORKING_DIRECTORY "${ARTIFACTS_PATH}"
				RESULT_VARIABLE upload_result1
				)
			if(upload_result1)
				message(FATAL_ERROR "error in upload ${package_generated_file})")
			endif()
			execute_process(
				COMMAND python ${ARTIFACTS_PATH}/upload_package.py --url=${PACKAGE_BASE_URL}/upload.php --filename=${package_cmake_generated_file}
				WORKING_DIRECTORY "${ARTIFACTS_PATH}"
				RESULT_VARIABLE upload_result2
				)
			if(upload_result2)
				message(FATAL_ERROR "error in upload ${package_cmake_generated_file})")
			endif()

			# 3. Obligatoriamente descomprimo el artefacto
			execute_process(
				COMMAND "${CMAKE_COMMAND}" -E tar zxf "${package_cmake_generated_file}"
				WORKING_DIRECTORY "${CMAKE_PREFIX_PATH}/"
				RESULT_VARIABLE uncompress_result
				)
			if(uncompress_result)
				message(FATAL_ERROR "Extracting ${package_cmake_generated_file} failed! Error ${uncompress_result}")
			endif()
			file(REMOVE "${package_generated_file}")
			file(REMOVE "${package_cmake_generated_file}")

		# me lo he descargdo y existe
		elseif(EXISTS "${package_uncompressed_file}")

			# lo descomprimo cacheado
			execute_process(
				COMMAND "${CMAKE_COMMAND}" -E tar zxf "${package_uncompressed_file}"
				WORKING_DIRECTORY "${CMAKE_PREFIX_PATH}/"
				RESULT_VARIABLE uncompress_result
				)
			if(uncompress_result)
				message(FATAL_ERROR "Extracting ${package_uncompressed_file} failed! Error ${uncompress_result}")
			endif()
			file(REMOVE "${package_uncompressed_file}")

		endif()
	endif()
	find_package(${PACKAGE} ${VERSION} REQUIRED)

	string(TOUPPER "${PACKAGE}" PACKAGE_UPPER)

	foreach(INCLUDE_DIR ${${PACKAGE_UPPER}_INCLUDE_DIRS})
		list(APPEND CMAKI_INCLUDE_DIRS "${INCLUDE_DIR}")
	endforeach()
	foreach(LIB_DIR ${${PACKAGE_UPPER}_LIBRARIES})
		list(APPEND CMAKI_LIBRARIES "${LIB_DIR}")
	endforeach()

	set(${PACKAGE_UPPER}_INCLUDE_DIRS "${${PACKAGE_UPPER}_INCLUDE_DIRS}" PARENT_SCOPE)
	set(${PACKAGE_UPPER}_LIBRARIES "${${PACKAGE_UPPER}_LIBRARIES}" PARENT_SCOPE)

	set(CMAKI_INCLUDE_DIRS "${CMAKI_INCLUDE_DIRS}" PARENT_SCOPE)
	set(CMAKI_LIBRARIES "${CMAKI_LIBRARIES}" PARENT_SCOPE)

endfunction()

macro(cmaki_package_version_check)
	###################################
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
	MESSAGE("Download from ${THE_URL} to ${INTO_FILE}")
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
	IF(NOT DEFINED PACKAGE_BASE_URL)
		MESSAGE(FATAL_ERROR "PACKAGE_BASE_URL: is not defined")
	ENDIF()
	get_filename_component(package_dir "${CMAKE_CURRENT_LIST_FILE}" PATH)
	# ${package_name} en realidad es paquete + version
	get_filename_component(package_name "${package_dir}" NAME)
	set(package_cmake_filename ${package_name}-${CMAKI_PLATFORM}.tar.gz)
	set(http_package_cmake_filename ${PACKAGE_BASE_URL}/download.php?file=${package_cmake_filename})

	# URL implicita
	# strip implicito

	set(depends_dir "${CMAKI_PATH}/../depends")
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
			file(READ "${package_compressed_md5}" THE_MD5 )
			string(REGEX MATCH "[0-9a-fA-F]*" THE_MD5 "${THE_MD5}")
			#cmaki_download_file("${http_package_cmake_filename}" "${package_compessed}" "${THE_MD5}" )
			cmaki_download_file("${http_package_cmake_filename}" "${package_compessed}")
			if( NOT "${COPY_SUCCESFUL}" )
				file(REMOVE "${package_compessed}")
			endif( NOT "${COPY_SUCCESFUL}" )
		else()
			MESSAGE(FATAL_ERROR "Checksum for ${package_name}-${CMAKI_PLATFORM}.tar.gz not found. Rejecting to download an untrustworthy file.")
		endif()
	endif()

	if(EXISTS "${package_compessed}")
		file(MAKE_DIRECTORY "${package_uncompressed_dir}")
		MESSAGE("Extracting ${package_compessed} into ${package_uncompressed_dir}...")
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

macro(cmaki_parse_parameters)
	set(PARAMETERS ${ARGV})
	list(GET PARAMETERS 0 _MAIN_NAME)
	list(REMOVE_AT PARAMETERS 0)
	SET(HAVE_TESTS FALSE)
	SET(HAVE_PCH FALSE)
	SET(HAVE_PTHREADS FALSE)
	set(_DEPENDS)
	set(_SOURCES)
	set(_TESTS)
	set(_PCH)
	set(NOW_IN SOURCES)
	while(PARAMETERS)
		list(GET PARAMETERS 0 PARM)
		if(PARM STREQUAL DEPENDS)
			set(NOW_IN DEPENDS)
		elseif(PARM STREQUAL SOURCES)
			set(NOW_IN SOURCES)
		elseif(PARM STREQUAL TESTS)
			set(NOW_IN TESTS)
		elseif(PARM STREQUAL PCH)
			set(NOW_IN PCH)
		elseif(PARM STREQUAL PTHREADS)
			SET(HAVE_PTHREADS TRUE)
		else()
			if(NOW_IN STREQUAL DEPENDS)
				set(_DEPENDS ${_DEPENDS} ${PARM})
			elseif(NOW_IN STREQUAL SOURCES)
				set(_SOURCES ${_SOURCES} ${PARM})
			elseif(NOW_IN STREQUAL TESTS)
				set(_TESTS ${_TESTS} ${PARM})
				SET(HAVE_TESTS TRUE)
			elseif(NOW_IN STREQUAL PCH)
				set(_PCH ${PARM})
				SET(HAVE_PCH TRUE)
			else()
				message(FATAL_ERROR "Unknown argument ${PARM}.")
			endif()
		endif()
		list(REMOVE_AT PARAMETERS 0)
	endwhile()
endmacro()

function(cmaki_executable)
	cmaki_parse_parameters(${ARGV})
	set(_EXECUTABLE_NAME ${_MAIN_NAME})
	source_group( "Source Files" FILES ${_SOURCES} )
	COMMONS_FLAGS()
	include_directories(..)
	include_directories(h)
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

function(cmaki_library)
	cmaki_parse_parameters(${ARGV})
	set(_LIBRARY_NAME ${_MAIN_NAME})
	source_group( "Source Files" FILES ${_SOURCES} )
	COMMONS_FLAGS()
	include_directories(..)
	include_directories(h)
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
	generate_vcxproj_user(${_LIBRARY_NAME})

endfunction()

function(cmaki_test)
	cmaki_parse_parameters(${ARGV})
	set(_TEST_NAME ${_MAIN_NAME})
	foreach(INCLUDE_DIR ${CMAKI_INCLUDE_DIRS})
		include_directories(${INCLUDE_DIR})
	endforeach()
	add_compile_options(-pthread)
	add_executable(${_TEST_NAME}_exe ${_SOURCES})
	target_link_libraries(${_TEST_NAME}_exe ${_DEPENDS})
	foreach(LIB_DIR ${CMAKI_LIBRARIES})
		target_link_libraries(${_TEST_NAME}_exe ${LIB_DIR})
		cmaki_install_3rdparty(${LIB_DIR})
	endforeach()
	target_link_libraries(${_TEST_NAME}_exe -lpthread)
	foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(    TARGETS ${_TEST_NAME}_exe
					DESTINATION ${BUILD_TYPE}
					CONFIGURATIONS ${BUILD_TYPE})
	endforeach()
	add_test(
		NAME ${_TEST_NAME}_exe
		COMMAND ${_TEST_NAME}_exe
		WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${CMAKE_BUILD_TYPE})

endfunction()

function(cmaki_gtest)
	cmaki_find_package(google-gtest)
	cmaki_find_package(google-gmock)
	cmaki_test(${ARGV})
endfunction()

macro (mark_as_internal _var)
    set(${_var} ${${_var}} CACHE INTERNAL "hide this!" FORCE)
endmacro(mark_as_internal _var)

macro (option_combobox _var options default_option comment)
    set(${_var} "${default_option}" CACHE STRING "${comment}")
    set(${_var}Values "${options}" CACHE INTERNAL "hide this!" FORCE)
    set_property(CACHE ${_var} PROPERTY STRINGS ${${_var}Values})
endmacro()

function(cmaki_install_file FROM)
    foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(FILES ${FROM} DESTINATION ${CMAKE_INSTALL_PREFIX}/${BUILD_TYPE} CONFIGURATIONS ${BUILD_TYPE})
    endforeach()
endfunction()

function(cmaki_install_file_into FROM TO)
    foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(FILES ${FROM} DESTINATION ${CMAKE_INSTALL_PREFIX}/${BUILD_TYPE}/${TO} CONFIGURATIONS ${BUILD_TYPE})
    endforeach()
endfunction()

function(cmaki_install_file_and_rename FROM NEWNAME)
    foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(FILES ${FROM} DESTINATION ${CMAKE_INSTALL_PREFIX}/${BUILD_TYPE} CONFIGURATIONS ${BUILD_TYPE} RENAME ${NEWNAME})
    endforeach()
endfunction()

function(cmaki_install_file_into_and_rename FROM TO NEWNAME)
    foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(FILES ${FROM} DESTINATION ${CMAKE_INSTALL_PREFIX}/${BUILD_TYPE}/${TO} CONFIGURATIONS ${BUILD_TYPE} RENAME ${NEWNAME})
    endforeach()
endfunction()

function(cmaki_install_files FROM)
    foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
        FILE(GLOB files ${FROM})
		INSTALL(FILES ${files} DESTINATION ${CMAKE_INSTALL_PREFIX}/${BUILD_TYPE} CONFIGURATIONS ${BUILD_TYPE})
    endforeach()
endfunction()

function(cmaki_install_files_into FROM TO)
    foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
        FILE(GLOB files ${FROM})
		INSTALL(FILES ${files} DESTINATION ${CMAKE_INSTALL_PREFIX}/${BUILD_TYPE}/${TO} CONFIGURATIONS ${BUILD_TYPE})
    endforeach()
endfunction()

macro(cmaki_install_inside_dir _DESTINE)
    file(GLOB DEPLOY_FILES_AND_DIRS "${_DESTINE}/*")
    foreach(ITEM ${DEPLOY_FILES_AND_DIRS})
       IF( IS_DIRECTORY "${ITEM}" )
          LIST( APPEND DIRS_TO_DEPLOY "${ITEM}" )
       ELSE()
          IF(ITEM STREQUAL "${_DESTINE}/CMakeLists.txt")
            MESSAGE("skipped file: ${_DESTINE}/CMakeLists.txt")
          ELSE()
            LIST(APPEND FILES_TO_DEPLOY "${ITEM}")
          ENDIF()
       ENDIF()
    endforeach()
	INSTALL(FILES ${FILES_TO_DEPLOY} DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_BUILD_TYPE})
	INSTALL(DIRECTORY ${DIRS_TO_DEPLOY} DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_BUILD_TYPE})
endmacro()

macro(cmaki_install_dir _DESTINE)
	INSTALL(DIRECTORY ${_DESTINE} DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_BUILD_TYPE})
endmacro()

