if(NOT DEFINED CMAKE_MODULE_PATH)
	set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})
endif()
include("${CMAKE_CURRENT_LIST_DIR}/facts/facts.cmake")

option(FIRST_ERROR "stop on first compilation error" FALSE)
option(COVERAGE "active coverage (only clang)" FALSE)
option(SANITIZER "active sanitizers" FALSE)

macro(cmaki_setup)
	enable_modern_cpp()
	enable_testing()
	set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/bin)
	SET(CMAKE_BUILD_TYPE_INIT Release)
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
	INSTALL(DIRECTORY ${DIRS_TO_DEPLOY} DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_BUILD_TYPE} USE_SOURCE_PERMISSIONS)
endmacro()

macro(cmaki_install_dir _DESTINE)
	INSTALL(DIRECTORY ${_DESTINE} DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_BUILD_TYPE} USE_SOURCE_PERMISSIONS)
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
	set(_SUFFIX_DESTINATION)
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
			if(NOT WIN32)
				# no enabled in windows
				set(HAVE_PTHREADS TRUE)
			endif()
		elseif(PARM STREQUAL INCLUDES)
			set(NOW_IN INCLUDES)
		elseif(PARM STREQUAL DESTINATION)
			set(NOW_IN DESTINATION)
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
			elseif(NOW_IN STREQUAL DESTINATION)
				set(_SUFFIX_DESTINATION ${PARM})
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
					DESTINATION ${BUILD_TYPE}/${_SUFFIX_DESTINATION}
					CONFIGURATIONS ${BUILD_TYPE})
	endforeach()
	generate_clang()

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
					DESTINATION ${BUILD_TYPE}/${_SUFFIX_DESTINATION}
					CONFIGURATIONS ${BUILD_TYPE})
	endforeach()
	generate_clang()

endfunction()

function(cmaki_test)
	cmaki_parse_parameters(${ARGV})
	set(_TEST_NAME ${_MAIN_NAME})
	MESSAGE("++ test ${_TEST_NAME}")
	include_directories(.)
	foreach(INCLUDE_DIR ${_INCLUDES})
		target_include_directories(${_TEST_NAME} ${INCLUDE_DIR})
	endforeach()
	if(HAVE_PTHREADS)
		add_compile_options(-pthread)
	endif()
	add_executable(${_TEST_NAME} ${_SOURCES})
	target_link_libraries(${_TEST_NAME} ${_DEPENDS})
	if(HAVE_PTHREADS)
		target_link_libraries(${_TEST_NAME} -lpthread)
	endif()
	foreach(BUILD_TYPE ${CMAKE_BUILD_TYPE})
		INSTALL(    TARGETS ${_TEST_NAME}
					DESTINATION ${BUILD_TYPE}/${_SUFFIX_DESTINATION}
					CONFIGURATIONS ${BUILD_TYPE})
	endforeach()

	IF(WIN32)
		add_test(
			NAME ${_TEST_NAME}__
			COMMAND ${_TEST_NAME}
			WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${CMAKE_BUILD_TYPE})
	ELSE()
		add_test(
			NAME ${_TEST_NAME}__
			COMMAND ${_TEST_NAME})
	ENDIF()
	generate_vcxproj_user(${_TEST_NAME})
	generate_clang()

endfunction()

macro(common_linking)

	set(PARAMETERS ${ARGV})
	list(GET PARAMETERS 0 TARGET)
	if ((CMAKE_CXX_COMPILER_ID STREQUAL "Clang") AND (CMAKE_BUILD_TYPE STREQUAL "Debug"))
		target_link_libraries(${TARGET} -lubsan)
	endif()

endmacro()

macro(common_flags)

	if ((CMAKE_CXX_COMPILER_ID STREQUAL "Clang") AND (CMAKE_BUILD_TYPE STREQUAL "Debug"))
		add_compile_options(-fsanitize=undefined)
	endif()

	if(SANITIZER)
		if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
			# (address,address-full,memory,thread)
			# http://clang.llvm.org/docs/AddressSanitizer.html
			set(SANITIZER_MODE "address")
			message("-- sanitizer enabled: ${SANITIZER_MODE} (clang)")
			add_definitions(-g -fno-omit-frame-pointer)
			SET(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -fsanitize=${SANITIZER_MODE}")
			SET(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=${SANITIZER_MODE}")
			add_definitions(-fsanitize=${SANITIZER_MODE})
		endif()
	endif()

	IF(COVERAGE)
		if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-instr-generate -fcoverage-mapping")
		else()
			# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-arcs")
			# SET(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -fprofile-arcs -lgcov")
			set(CMAKE_C_OUTPUT_EXTENSION_REPLACE 1)
			set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O0 -coverage")
			set(CMAKE_CXX_OUTPUT_EXTENSION_REPLACE 1)
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0 -coverage")
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-elide-constructors")
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-inline")
		endif()
	endif()

	if(WIN32 AND (NOT MINGW) AND (NOT MSYS))
		# c++ exceptions and RTTI
		# add_definitions(/D_HAS_EXCEPTIONS=0)
		# add_definitions(/GR-)
		add_definitions(/wd4251)
		add_definitions(/wd4275)
		add_definitions(/wd4239)
		add_definitions(/wd4316)
		add_definitions(/wd4127)
		add_definitions(/wd4245)
		add_definitions(/wd4458)
		add_definitions(/wd4146)
		add_definitions(/wd4244)
		add_definitions(/wd4189)
		add_definitions(/wd4100)
		add_definitions(/WX /W4)
		add_definitions(-Zm200)
	endif()

endmacro()

macro(enable_modern_cpp)

	if(WIN32 AND (NOT MINGW) AND (NOT MSYS))
		add_definitions(/EHsc)
	else()
		# add_definitions(-fno-rtti -fno-exceptions )
		# activate all warnings and convert in errors
		# add_definitions(-Weffc++)
		# add_definitions(-pedantic -pedantic-errors)
		
		# Python: need disabling: initialization discards ‘const’ qualifier from pointer target type
		# add_definitions(-Werror)
		
		add_definitions(-Wall -Wextra -Waggregate-return -Wcast-align -Wcast-qual -Wconversion)
		add_definitions(-Wdisabled-optimization -Wformat=2 -Wformat-nonliteral -Wformat-security -Wformat-y2k)
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
		add_definitions(-Wno-error=unused-variable)
		add_definitions(-Wno-error=unused-parameter)
		add_definitions(-Wno-error=deprecated-declarations)
		add_definitions(-Wno-error=missing-include-dirs)
		add_definitions(-Wno-error=packed)
		add_definitions(-Wno-error=switch-default)
		add_definitions(-Wno-error=float-equal)
		add_definitions(-Wno-error=invalid-pch)
		add_definitions(-Wno-error=cast-qual)
		add_definitions(-Wno-error=conversion)
		add_definitions(-Wno-error=switch-enum)
		add_definitions(-Wno-error=redundant-decls)
		add_definitions(-Wno-error=stack-protector)
		add_definitions(-Wno-error=extra)
		add_definitions(-Wno-error=unused-result)
		add_definitions(-Wno-error=sign-compare)

		# raknet
		add_definitions(-Wno-error=address)
		add_definitions(-Wno-error=cast-qual)
		add_definitions(-Wno-error=missing-field-initializers)
		add_definitions(-Wno-error=write-strings)
		add_definitions(-Wno-error=format-nonliteral)

		# sdl2
		add_definitions(-Wno-error=sign-conversion)

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
			add_definitions(-Wno-error=unused-but-set-variable)
			add_definitions(-Wno-error=unused-local-typedefs)
			# add_definitions(-Wno-error=float-conversion)
		else()
			add_definitions(-Wstrict-aliasing=2)
			add_definitions(-Wno-error=format-nonliteral)
			add_definitions(-Wno-error=cast-align)
			add_definitions(-Wno-error=deprecated-register)
			add_definitions(-Wno-error=mismatched-tags)
			add_definitions(-Wno-error=overloaded-virtual)
			add_definitions(-Wno-error=unused-private-field)
			add_definitions(-Wno-error=unreachable-code)
			# add_definitions(-Wno-error=discarded-qualifiers)
		endif()

		# In Linux default now is not export symbols
		# add_definitions(-fvisibility=hidden)

		# stop in first error
		if(FIRST_ERROR)
			add_definitions(-Wfatal-errors)
		endif()

	endif()

	if (NOT DEFINED EXTRA_DEF)
		if(NOT WIN32 OR MINGW OR MSYS)
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
endmacro()

# TODO: only works in win64 ?
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

macro(generate_clang)
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

function(echo_target_property tgt prop)
  # v for value, d for defined, s for set
  get_property(v TARGET ${tgt} PROPERTY ${prop})
  get_property(d TARGET ${tgt} PROPERTY ${prop} DEFINED)
  get_property(s TARGET ${tgt} PROPERTY ${prop} SET)
 
  # only produce output for values that are set
  if(s)
    message("tgt='${tgt}' prop='${prop}'")
    message("  value='${v}'")
    message("  defined='${d}'")
    message("  set='${s}'")
    message("")
  endif()
endfunction()
 
function(echo_target tgt)
  if(NOT TARGET ${tgt})
    message("There is no target named '${tgt}'")
    return()
  endif()
 
  set(props
DEBUG_OUTPUT_NAME
DEBUG_POSTFIX
RELEASE_OUTPUT_NAME
RELEASE_POSTFIX
ARCHIVE_OUTPUT_DIRECTORY
ARCHIVE_OUTPUT_DIRECTORY_DEBUG
ARCHIVE_OUTPUT_DIRECTORY_RELEASE
ARCHIVE_OUTPUT_NAME
ARCHIVE_OUTPUT_NAME_DEBUG
ARCHIVE_OUTPUT_NAME_RELEASE
AUTOMOC
AUTOMOC_MOC_OPTIONS
BUILD_WITH_INSTALL_RPATH
BUNDLE
BUNDLE_EXTENSION
COMPILE_DEFINITIONS
COMPILE_DEFINITIONS_DEBUG
COMPILE_DEFINITIONS_RELEASE
COMPILE_FLAGS
DEBUG_POSTFIX
RELEASE_POSTFIX
DEFINE_SYMBOL
ENABLE_EXPORTS
EXCLUDE_FROM_ALL
EchoString
FOLDER
FRAMEWORK
Fortran_FORMAT
Fortran_MODULE_DIRECTORY
GENERATOR_FILE_NAME
GNUtoMS
HAS_CXX
IMPLICIT_DEPENDS_INCLUDE_TRANSFORM
IMPORTED
IMPORTED_CONFIGURATIONS
IMPORTED_IMPLIB
IMPORTED_IMPLIB_DEBUG
IMPORTED_IMPLIB_RELEASE
IMPORTED_LINK_DEPENDENT_LIBRARIES
IMPORTED_LINK_DEPENDENT_LIBRARIES_DEBUG
IMPORTED_LINK_DEPENDENT_LIBRARIES_RELEASE
IMPORTED_LINK_INTERFACE_LANGUAGES
IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG
IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE
IMPORTED_LINK_INTERFACE_LIBRARIES
IMPORTED_LINK_INTERFACE_LIBRARIES_DEBUG
IMPORTED_LINK_INTERFACE_LIBRARIES_RELEASE
IMPORTED_LINK_INTERFACE_MULTIPLICITY
IMPORTED_LINK_INTERFACE_MULTIPLICITY_DEBUG
IMPORTED_LINK_INTERFACE_MULTIPLICITY_RELEASE
IMPORTED_LOCATION
IMPORTED_LOCATION_DEBUG
IMPORTED_LOCATION_RELEASE
IMPORTED_NO_SONAME
IMPORTED_NO_SONAME_DEBUG
IMPORTED_NO_SONAME_RELEASE
IMPORTED_SONAME
IMPORTED_SONAME_DEBUG
IMPORTED_SONAME_RELEASE
IMPORT_PREFIX
IMPORT_SUFFIX
INCLUDE_DIRECTORIES
INSTALL_NAME_DIR
INSTALL_RPATH
INSTALL_RPATH_USE_LINK_PATH
INTERPROCEDURAL_OPTIMIZATION
INTERPROCEDURAL_OPTIMIZATION_DEBUG
INTERPROCEDURAL_OPTIMIZATION_RELEASE
LABELS
LIBRARY_OUTPUT_DIRECTORY
LIBRARY_OUTPUT_DIRECTORY_DEBUG
LIBRARY_OUTPUT_DIRECTORY_RELEASE
LIBRARY_OUTPUT_NAME
LIBRARY_OUTPUT_NAME_DEBUG
LIBRARY_OUTPUT_NAME_RELEASE
LINKER_LANGUAGE
LINK_DEPENDS
LINK_FLAGS
LINK_FLAGS_DEBUG
LINK_FLAGS_RELEASE
LINK_INTERFACE_LIBRARIES
LINK_INTERFACE_LIBRARIES_DEBUG
LINK_INTERFACE_LIBRARIES_RELEASE
LINK_INTERFACE_MULTIPLICITY
LINK_INTERFACE_MULTIPLICITY_DEBUG
LINK_INTERFACE_MULTIPLICITY_RELEASE
LINK_SEARCH_END_STATIC
LINK_SEARCH_START_STATIC
LOCATION
LOCATION_DEBUG
LOCATION_RELEASE
MACOSX_BUNDLE
MACOSX_BUNDLE_INFO_PLIST
MACOSX_FRAMEWORK_INFO_PLIST
MAP_IMPORTED_CONFIG_DEBUG
MAP_IMPORTED_CONFIG_RELEASE
OSX_ARCHITECTURES
OSX_ARCHITECTURES_DEBUG
OSX_ARCHITECTURES_RELEASE
OUTPUT_NAME
OUTPUT_NAME_DEBUG
OUTPUT_NAME_RELEASE
POST_INSTALL_SCRIPT
PREFIX
PRE_INSTALL_SCRIPT
PRIVATE_HEADER
PROJECT_LABEL
PUBLIC_HEADER
RESOURCE
RULE_LAUNCH_COMPILE
RULE_LAUNCH_CUSTOM
RULE_LAUNCH_LINK
RUNTIME_OUTPUT_DIRECTORY
RUNTIME_OUTPUT_DIRECTORY_DEBUG
RUNTIME_OUTPUT_DIRECTORY_RELEASE
RUNTIME_OUTPUT_NAME
RUNTIME_OUTPUT_NAME_DEBUG
RUNTIME_OUTPUT_NAME_RELEASE
SKIP_BUILD_RPATH
SOURCES
SOVERSION
STATIC_LIBRARY_FLAGS
STATIC_LIBRARY_FLAGS_DEBUG
STATIC_LIBRARY_FLAGS_RELEASE
SUFFIX
TYPE
VERSION
VS_DOTNET_REFERENCES
VS_GLOBAL_WHATEVER
VS_GLOBAL_KEYWORD
VS_GLOBAL_PROJECT_TYPES
VS_KEYWORD
VS_SCC_AUXPATH
VS_SCC_LOCALPATH
VS_SCC_PROJECTNAME
VS_SCC_PROVIDER
VS_WINRT_EXTENSIONS
VS_WINRT_REFERENCES
WIN32_EXECUTABLE
XCODE_ATTRIBUTE_WHATEVER
)

  message("======================== ${tgt} ========================")
  foreach(p ${props})
    echo_target_property("${t}" "${p}")
  endforeach()
  message("")
endfunction()

function(echo_targets)
  set(tgts ${ARGV})
  foreach(t ${tgts})
    echo_target("${t}")
  endforeach()
endfunction()
