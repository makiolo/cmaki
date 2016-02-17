include("${CMAKE_CURRENT_LIST_DIR}/facts/facts.cmake")

option(FIRST_ERROR "stop on first compilation error" FALSE)
option(COVERAGE "active coverage (only clang)" FALSE)
option(SANITIZER "active sanitizers (address,address-full,memory,thread) (only clang)" "")

macro(cmaki_setup)

	enable_modern_cpp()
	enable_testing()
	# default install prefix
	set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/bin)

endmacro()

macro(GENERATE_CLANG)
	# Generate .clang_complete for full completation in vim + clang_complete
	set(extra_parameters "")
	get_property(dirs DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)
	foreach(dir ${dirs})
	  set(extra_parameters ${extra_parameters} -I${dir})
	endforeach()
	get_property(dirs DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY COMPILE_DEFINITIONS)
	foreach(dir ${dirs})
	  set(extra_parameters ${extra_parameters} -D${dir})
	endforeach()
	STRING(REGEX REPLACE ";" "\n" extra_parameters "${extra_parameters}")
	FILE(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/.clang_complete" "${extra_parameters}\n")
endmacro()

macro(generate_vcxproj_user _EXECUTABLE_NAME)
    IF(MSVC)
        set(project_vcxproj_user "${CMAKE_CURRENT_BINARY_DIR}/${_EXECUTABLE_NAME}.vcxproj.user")
        if (NOT EXISTS ${project_vcxproj_user})
            FILE(WRITE "${project_vcxproj_user}"
            "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
            "<Project ToolsVersion=\"12.0\" xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">\n"
            "<PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='Debug|x64'\">\n"
            "<LocalDebuggerWorkingDirectory>$(TargetDir)</LocalDebuggerWorkingDirectory>\n"
            "<DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>\n"
            "</PropertyGroup>\n"
            "<PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='RelWithDebInfo|x64'\">\n"
            "<LocalDebuggerWorkingDirectory>$(TargetDir)</LocalDebuggerWorkingDirectory>\n"
            "<DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>\n"
            "</PropertyGroup>\n"
            "<PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='Release|x64'\">\n"
            "<LocalDebuggerWorkingDirectory>$(TargetDir)</LocalDebuggerWorkingDirectory>\n"
            "<DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>\n"
            "</PropertyGroup>\n"
            "<PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='MinSizeRel|x64'\">\n"
            "<LocalDebuggerWorkingDirectory>$(TargetDir)</LocalDebuggerWorkingDirectory>\n"
            "<DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>\n"
            "</PropertyGroup>\n"
            "</Project>\n")
        endif()
    ENDIF()
endmacro()

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
	set(_INCLUDES)
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
		elseif(PARM STREQUAL INCLUDES)
			set(NOW_IN INCLUDES)
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
			elseif(NOW_IN STREQUAL INCLUDES)
				set(_INCLUDES ${_INCLUDES} ${PARM})
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
	MESSAGE("++ executable ${_EXECUTABLE_NAME}")
	source_group( "Source Files" FILES ${_SOURCES} )
	common_flags()
	include_directories(.)
	foreach(INCLUDE_DIR ${_INCLUDES})
		target_include_directories(${_EXECUTABLE_NAME} ${INCLUDE_DIR})
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
	MESSAGE("++ library ${_LIBRARY_NAME}")
	source_group( "Source Files" FILES ${_SOURCES} )
	common_flags()
	include_directories(.)
	foreach(INCLUDE_DIR ${_INCLUDES})
		target_include_directories(${_LIBRARY_NAME} ${INCLUDE_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		add_compile_options(-pthread)
	endif()
	add_library(${_LIBRARY_NAME} SHARED ${_SOURCES})
	target_link_libraries(${_LIBRARY_NAME} ${_DEPENDS})
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
	MESSAGE("++ test ${_TEST_NAME}")
	include_directories(.)
	foreach(INCLUDE_DIR ${_INCLUDES})
		target_include_directories(${_TEST_NAME} ${INCLUDE_DIR})
	endforeach()
	add_compile_options(-pthread)
	add_executable(${_TEST_NAME} ${_SOURCES})
	target_link_libraries(${_TEST_NAME} ${_DEPENDS})
	target_link_libraries(${_TEST_NAME} -lpthread)
	foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(    TARGETS ${_TEST_NAME}
					DESTINATION ${BUILD_TYPE}
					CONFIGURATIONS ${BUILD_TYPE})
	endforeach()

	add_test(
		NAME ${_TEST_NAME}__
		COMMAND ${_TEST_NAME}
		WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${CMAKE_BUILD_TYPE})

endfunction()

macro(common_flags)

	if(SANITIZER)
		add_definitions(-g3)
		# "address-full" "memory" "thread"
		SET(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -fsanitize=${SANITIZER}")
		SET(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=${SANITIZER}")
		add_definitions(-fsanitize=${SANITIZER})
	endif()
	IF(COVERAGE)
		if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-instr-generate -fcoverage-mapping")
		else()
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-arcs")
			SET(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -fprofile-arcs -lgcov")
		endif()
	endif()

	if(NOT WIN32)
		SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")
		if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
			SET( CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -lpthread" )
		endif()
		add_compile_options(-pthread)

		# if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
		# 	# enable OpenMP (need gomp dev)
		# 	SET(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -fopenmp")
		# 	SET(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -lgomp -lrt")
		# endif()
	else()
		# c++ exceptions and RTTI
		#add_definitions(/D_HAS_EXCEPTIONS=0)
		#add_definitions(/GR-)
		add_definitions(/wd4251)
		add_definitions(/wd4275)
		# Avoid warning as error with / WX / W4
		# conversion from 'std::reference_wrapper<Chunk>' to 'std::reference_wrapper<Chunk> &
		add_definitions(/wd4239)
		# warning C4316: 'PhysicsManager' : object allocated on the heap may not be aligned 16
		add_definitions(/wd4316)
		# conditional expression is constant
		add_definitions(/wd4127)
		# conversion from 'int' to 'unsigned int', signed/unsigned mismatch
		add_definitions(/wd4245)
		# declaration of 'next' hides class membe
		add_definitions(/wd4458)

		add_definitions(/WX /W4)
		add_definitions(-Zm200)
	endif()

	# include_directories(BEFORE ${TOOLCHAIN_ROOT}/include)
	# link_directories(${TOOLCHAIN_ROOT}/lib)
	# SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -ltcmalloc")
endmacro()

macro(enable_modern_cpp)

	if(WIN32)
		add_definitions(/EHsc)
		#add_definitions(/GR-)
		#add_definitions(/D_HAS_EXCEPTIONS=0)
	else()
		# add_definitions(-fno-rtti -fno-exceptions )
		# activate all warnings and convert in errors
		# add_definitions(-Weffc++)
		# borro pedantic, en dune falla
		# add_definitions(-pedantic -pedantic-errors)
		add_definitions(-Wall -Wextra -Waggregate-return -Wcast-align -Wcast-qual -Wconversion)
		add_definitions(-Wdisabled-optimization -Werror -Wfloat-equal -Wformat=2 -Wformat-nonliteral -Wformat-security -Wformat-y2k)
		add_definitions(-Wimport  -Winit-self  -Winline -Winvalid-pch -Wlong-long -Wmissing-field-initializers -Wmissing-format-attribute)
		add_definitions(-Wpointer-arith -Wredundant-decls -Wshadow)
		add_definitions(-Wstack-protector -Wunreachable-code -Wunused)
		add_definitions(-Wunused-parameter -Wvariadic-macros -Wwrite-strings)
		add_definitions(-Wswitch-default -Wswitch-enum)
		# only gcc
		# convert error in warnings
		add_definitions(-Wno-error=shadow)
		add_definitions(-Wno-error=long-long)
		add_definitions(-Wno-error=aggregate-return)
		add_definitions(-Wno-error=aggregate-return)
		add_definitions(-Wno-error=unused-variable)
		add_definitions(-Wno-error=unused-parameter)
		add_definitions(-Wno-error=deprecated-declarations)
		add_definitions(-Wno-error=missing-include-dirs)
		add_definitions(-Wno-error=packed)
		add_definitions(-Wno-error=switch-default)
		add_definitions(-Wno-error=float-equal)
		add_definitions(-Wno-error=invalid-pch)
		add_definitions(-Wno-error=cast-qual)
		add_definitions(-Wno-error=float-conversion)
		add_definitions(-Wno-error=conversion)
		add_definitions(-Wno-error=switch-enum)
		add_definitions(-Wno-error=unused-local-typedefs)
		add_definitions(-Wno-error=redundant-decls)
		add_definitions(-Wno-error=stack-protector)
		add_definitions(-Wno-error=extra)
		add_definitions(-Wno-error=unused-result)
		add_definitions(-Wno-error=sign-compare)

		# TODO: remove
		add_definitions(-Wno-error=reorder)

		# if not have openmp
		add_definitions(-Wno-error=unknown-pragmas)

		if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
			add_definitions(-Wno-error=suggest-attribute=format)
			add_definitions(-Wno-error=suggest-attribute=noreturn)
			add_definitions(-Wno-aggregate-return)
			add_definitions(-Wno-long-long)
			add_definitions(-Wno-shadow)
			add_definitions(-Wno-strict-aliasing)
			add_definitions(-Wno-error=inline)
			add_definitions(-Wno-error=maybe-uninitialized)
		else()
			add_definitions(-Wstrict-aliasing=2)
			add_definitions(-Wno-error=format-nonliteral)
			add_definitions(-Wno-error=cast-align)
			add_definitions(-Wno-error=deprecated-register)
			# poner override en metacommon y borrar
			add_definitions(-Wno-error=inconsistent-missing-override)
			add_definitions(-Wno-error=mismatched-tags)
			add_definitions(-Wno-error=overloaded-virtual)
			add_definitions(-Wno-error=unused-private-field)
		endif()

		# In Linux default now is not export symbols
		# add_definitions(-fvisibility=hidden)

		# stop in first error
		if(FIRST_ERROR)
			add_definitions(-Wfatal-errors)
		endif()

	endif()

	if (NOT DEFINED EXTRA_DEF)
		if(NOT WIN32)
			include(CheckCXXCompilerFlag)
			CHECK_CXX_COMPILER_FLAG("-std=c++14" COMPILER_SUPPORTS_CXX14)
			CHECK_CXX_COMPILER_FLAG("-std=c++1y" COMPILER_SUPPORTS_CXX1Y)
			CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
			CHECK_CXX_COMPILER_FLAG("-std=c++0x" COMPILER_SUPPORTS_CXX0X)

			if(COMPILER_SUPPORTS_CXX14)
				set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
				message("-- C++14 Enabled")
			elseif(COMPILER_SUPPORTS_CXX11)
				set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
				message("-- C++11 Enabled")
			elseif(COMPILER_SUPPORTS_CXX0X)
				set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
				message("-- C++0x Enabled")
			else()
				message(STATUS "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
			endif()
		endif()
	else()
		add_definitions(${EXTRA_DEF})
	endif()
	SET(CMAKE_BUILD_TYPE_INIT Release)
endmacro()

macro(generate_vcxproj_user _EXECUTABLE_NAME)
	IF(MSVC)
		set(project_vcxproj_user "${CMAKE_CURRENT_BINARY_DIR}/${_EXECUTABLE_NAME}.vcxproj.user")
		if (NOT EXISTS ${project_vcxproj_user})
			FILE(WRITE "${project_vcxproj_user}"
				"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
				"<Project ToolsVersion=\"12.0\" xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">\n"
				"<PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='Debug|x64'\">\n"
				"<LocalDebuggerWorkingDirectory>$(TargetDir)</LocalDebuggerWorkingDirectory>\n"
				"<DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>\n"
				"</PropertyGroup>\n"
				"<PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='RelWithDebInfo|x64'\">\n"
				"<LocalDebuggerWorkingDirectory>$(TargetDir)</LocalDebuggerWorkingDirectory>\n"
				"<DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>\n"
				"</PropertyGroup>\n"
				"<PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='Release|x64'\">\n"
				"<LocalDebuggerWorkingDirectory>$(TargetDir)</LocalDebuggerWorkingDirectory>\n"
				"<DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>\n"
				"</PropertyGroup>\n"
				"<PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='MinSizeRel|x64'\">\n"
				"<LocalDebuggerWorkingDirectory>$(TargetDir)</LocalDebuggerWorkingDirectory>\n"
				"<DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>\n"
				"</PropertyGroup>\n"
				"</Project>\n")
		endif()
	ENDIF()
endmacro()

function(DUNE_EXECUTABLE _EXECUTABLE_NAME _SOURCE_FILES)

	source_group( "Source Files" FILES ${_SOURCE_FILES} )
	include_directories(..)
	include_directories(h)
	ADD_EXECUTABLE(${_EXECUTABLE_NAME} ${_SOURCE_FILES})
	generate_vcxproj_user(${_EXECUTABLE_NAME})

endfunction()

function(DUNE_LIBRARY)

	set(PARAMETERS ${ARGV})
	list(GET PARAMETERS 0 LIBNAME)
	list(REMOVE_AT PARAMETERS 0)

	SET(HAVE_TESTS FALSE)
	SET(HAVE_PCH FALSE)
	set(TARGET_DEPENDENCIES)
	set(EXTRA_SOURCES)
	set(TESTS_SOURCES)
	set(PCH_SOURCE)
	while(PARAMETERS)
		list(GET PARAMETERS 0 PARM)
		if(PARM STREQUAL DEPENDENCIES)
			set(NOW_IN DEPENDENCIES)
		elseif(PARM STREQUAL EXTRA_SOURCES)
			set(NOW_IN EXTRA_SOURCES)
		elseif(PARM STREQUAL TESTS)
			set(NOW_IN TESTS)
		elseif(PARM STREQUAL PCH)
			set(NOW_IN PCH)
		else()
			if(NOW_IN STREQUAL DEPENDENCIES)
				set(TARGET_DEPENDENCIES ${TARGET_DEPENDENCIES} ${PARM})
			elseif(NOW_IN STREQUAL EXTRA_SOURCES)
				set(EXTRA_SOURCES ${EXTRA_SOURCES} ${PARM})
			elseif(NOW_IN STREQUAL TESTS)
				set(TESTS_SOURCES ${TESTS_SOURCES} ${PARM})
				SET(HAVE_TESTS TRUE)
			elseif(NOW_IN STREQUAL PCH)
				set(PCH_SOURCE ${PARM})
				SET(HAVE_PCH TRUE)
			else()
				message(FATAL_ERROR "Unknown argument ${PARM}.")
			endif()
		endif()
		list(REMOVE_AT PARAMETERS 0)
	endwhile()

	foreach(INCLUDE_DIR ${CMAKI_INCLUDE_DIRS})
		include_directories(${INCLUDE_DIR})
	endforeach()
	INCLUDE_DIRECTORIES(..)
	INCLUDE_DIRECTORIES(h)

	file( GLOB SOURCE_FILES [Cc]/*.c [Cc]/*.cpp [Cc]/*.cxx *.cpp *.c *.cxx )
	file( GLOB HEADERS_FILES [Hh]/*.h [Hh]/*.hpp [Hh]/*.hxx [Hh][Pp][Pp]/*.hpp [Hh][Pp][Pp]/*.hxx *.h *.hpp *.hxx )
	IF(WIN32)
		file( GLOB SPECIFIC_PLATFORM c/win32/*.cpp )
		INCLUDE_DIRECTORIES(c/win32)
	ELSEIF(UNIX)
		file( GLOB SPECIFIC_PLATFORM c/linux/*.cpp )
		INCLUDE_DIRECTORIES(c/linux)
	ELSEIF(MAC)
		file( GLOB SPECIFIC_PLATFORM c/mac/*.cpp )
		INCLUDE_DIRECTORIES(c/mac)
	ELSEIF(ANDROID)
		file( GLOB SPECIFIC_PLATFORM c/android/*.cpp )
		INCLUDE_DIRECTORIES(c/android)
	ENDIF()

	SET(SOURCE_FILES ${SOURCE_FILES} "${SPECIFIC_PLATFORM}")
	source_group( "c" FILES ${SOURCE_FILES})
	source_group( "h" FILES ${HEADERS_FILES})

	common_flags()
	ADD_LIBRARY(${LIBNAME} SHARED ${SOURCE_FILES} ${HEADERS_FILES} ${EXTRA_SOURCES})
	TARGET_LINK_LIBRARIES(${LIBNAME} ${TARGET_DEPENDENCIES})
	foreach(LIB_DIR ${CMAKI_LIBRARIES})
		target_link_libraries(${LIBNAME} ${LIB_DIR})
		cmaki_install_3rdparty(${LIB_DIR})
	endforeach()

	IF(WIN32)
		# library with suffix python friendly
		set_target_properties(${LIBNAME} PROPERTIES SUFFIX .pyd)
	ENDIF()

	if(HAVE_PCH)

		# TODO: problems clang
		# if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
		# 	include(${CMAKE_CURRENT_LIST_DIR}/cmaki/ci/cotire.cmake)
		# 	set_target_properties(${LIBNAME} PROPERTIES COTIRE_CXX_PREFIX_HEADER_INIT "h/${PCH_SOURCE}")
		# 	set_target_properties(${LIBNAME} PROPERTIES COTIRE_UNITY_LINK_LIBRARIES_INIT "COPY")
		# 	cotire(${LIBNAME})
		# endif()
	endif()

	GENERATE_CLANG()

	foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(TARGETS ${LIBNAME}
			DESTINATION ${BUILD_TYPE}
			CONFIGURATIONS ${BUILD_TYPE})
	endforeach()

endfunction()

function(GENERATE_LIB)

	DUNE_LIBRARY(${ARGSN})

endfunction()

macro(common_flags_deprecated)
	if(SANITIZER)
		add_definitions(-g3)
		# "address-full" "memory" "thread"
		SET(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -fsanitize=${SANITIZER}")
		SET(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=${SANITIZER}")
		add_definitions(-fsanitize=${SANITIZER})
	endif()
	IF(COVERAGE)
		if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-instr-generate -fcoverage-mapping")
		else()
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-arcs")
			SET(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -fprofile-arcs -lgcov")
		endif()
	endif()

	if(NOT WIN32)
		SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -pthread" )
		if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
			SET( CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -lpthread" )
		endif()
	endif()

	# include_directories(BEFORE ${TOOLCHAIN_ROOT}/include)
	# link_directories(${TOOLCHAIN_ROOT}/lib)
	# SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -ltcmalloc")
endmacro()

