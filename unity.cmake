# CMake module to integrate Unity - unit test framework for C.
# 
# For more detials please check http://www.throwtheswitch.org/unity.
#
# Copyright (c) 2016 Piotr L. Figlarek
#
# Usage
# -----
# Include module and add each file with unit tests via unity_add_test(...) function, 
# like presented below:
#
#     unity_add_test(unit_test_name test_file.c)
#
# In case when unit test should be linked with library please use 
# unity_link_libraries(...) function like below:
#
#     unity_add_test(my_test my_test_file.c)
#     unity_link_libraries(my_test some_library)
#
# Recommended method to execute all unit tests is to execute following command
# 
#     make clean all utest
#
# or
#
#     make clean all test
#
# if tests were enabled via enable_testing().
#
# License (MIT)
# -------------
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# name of the target with all Unity tests
set(UNITY_TARGET utest CACHE STRING "Common target for all Unity tests")

# latest Unity software
set(UNITY_MASTER_URL https://github.com/ThrowTheSwitch/Unity/archive/master.zip)

# Unity source code root directory
set(UNITY_DIR ${CMAKE_BINARY_DIR}/Unity-master)

# find and adjust all Unity variables 
function(find_unity)
    # check if Unity is available
    find_file(UNITY_C unity.c
              PATHS ${UNITY_DIR}/src)
    find_file(UNITY_H unity.h
              PATHS ${UNITY_DIR}/src)
    if(UNITY_C)
        set(UNITY TRUE PARENT_SCOPE)
    endif()
endfunction()

# unzip Unity
function(unzip_unity ZIP)
    # find unzip to extract archive
    find_program(UNZIP unzip)
    if(NOT UNZIP)
        message(STATUS "Missing unzip")
        return()
    endif()

    # extract archive
    message("Extracting archive ${ZIP}")
    execute_process(COMMAND ${UNZIP} -oq ${ZIP}
                    RESULT_VARIABLE RESULT)
    # check unzip result
    if(NOT ${RESULT} EQUAL 0)
        message(STATUS "unzip ${ZIP} FAILED!")
        return()
    endif()
endfunction()

# try to download Unity via wget
function(download_unity_wget URL ZIP)
    # fing wget to download Unity
    find_program(WGET wget)
    if(NOT WGET)
        message(STATUS "Missing wget")
        return()
    endif()

    # download Unity    
    message(STATUS "Using wget to download Unity from ${URL}")
    execute_process(COMMAND ${WGET} -O ${ZIP} ${URL}
                    TIMEOUT 20
                    RESULT_VARIABLE RESULT)
    # check download result
    if(NOT ${RESULT} EQUAL 0)
        message(STATUS "wget ${URL} FAILED!")
        return()
    endif()
endfunction()

# try to download Unity via cURL
function(download_unity_curl URL ZIP)
    # fing cURL to download Unity
    find_program(CURL curl)
    if(NOT CURL)
        message(STATUS "Missing cURL")
        return()
    endif()

    # download Unity    
    message(STATUS "Using cURL to download Unity from ${URL}")
    execute_process(COMMAND ${CURL} -L -o ${ZIP} ${URL}
                    TIMEOUT 20
                    RESULT_VARIABLE RESULT)
    # check download result
    if(NOT ${RESULT} EQUAL 0)
        message(STATUS "curl ${URL} FAILED!")
        return()
    endif()
endfunction()

# fing ruby required by Unity 
function(find_ruby)
    find_program(RUBY ruby)
endfunction()


# 1st try: download Unity via wget
find_unity()
if(NOT UNITY)
    download_unity_wget(${UNITY_MASTER_URL} unity.zip)
    unzip_unity(unity.zip)
endif()
# 2nd try: download Unity via cURL
find_unity()
if(NOT UNITY)
    download_unity_curl(${UNITY_MASTER_URL} unity.zip)
    unzip_unity(unity.zip)
endif()
# final check
find_unity()
if(NOT UNITY)
    message(FATAL_ERROR "Unable to download Unity")
endif()

# check if ruby is available
find_ruby()
if(NOT RUBY)
    message(FATAL_ERROR "Please install ruby")
endif()

# create static library for all Unity tests
add_library(unity STATIC ${UNITY_C})

# show results from all Unity tests
add_custom_target(${UNITY_TARGET}
    COMMAND ${RUBY} ${UNITY_DIR}/auto/unity_test_summary.rb ./
    COMMENT "Show Unity tests summary"
)

# add Unity test
#  arg1 - test name
#  arg2 - unit test main file
#  arg3, ... - all other sources needed for test
function(unity_add_test TEST_NAME)
    # first file should contain full Unity test definition
    get_filename_component(TEST_FULLPATH ${ARGV1} REALPATH)
    # generate Unity test runner
    set(TEST_RUNNER ${TEST_NAME}_runner.c)
    add_custom_command(
        OUTPUT ${TEST_RUNNER}
        COMMAND ${RUBY} ${UNITY_DIR}/auto/generate_test_runner.rb
                        ${TEST_FULLPATH}
                        ${TEST_RUNNER} > /dev/null
        DEPENDS ${ARGV1}
        COMMENT "Generating test runner for test: ${TEST_RUNNER}"
    )

    # include directory with unity.h file
    include_directories(${UNITY_DIR}/src)
    # build test application
    add_executable(${UNITY_TARGET}.${TEST_NAME} ${TEST_RUNNER} ${ARGN})
    # and link it with Unity lib
    target_link_libraries(${UNITY_TARGET}.${TEST_NAME} unity)

    # run test and prepare test result file
    set(TEST_RESULT ${TEST_NAME}.testresults)
    add_custom_command(
        OUTPUT ${TEST_RESULT}
        COMMAND ${UNITY_TARGET}.${TEST_NAME} > ${TEST_NAME}.testresults || true    # dirty hack to ignore any potential error
        COMMENT "Running test: ${TEST_NAME}"
        DEPENDS ${UNITY_TARGET}.${TEST_NAME}
    )

    # fake target to build & run tests
    set(TEST_EXECUTOR ${TEST_NAME}.executor)
    add_custom_target(${TEST_EXECUTOR}
        SOURCES ${TEST_RESULT}
    )

    # connect this test with Unity test target
    add_dependencies(${UNITY_TARGET} ${TEST_EXECUTOR})

    # add this test to CTest
    add_test(${UNITY_TARGET}.${TEST_NAME} ${UNITY_TARGET}.${TEST_NAME})

    message(STATUS "Unity test '${TEST_NAME}' added")
endfunction()

# link unity test with library
#  arg1 - test name
#  arg2, ... - all STATIC librarties
function(unity_link_libraries TEST_NAME)
    # link each library with test target
    foreach(lib ${ARGN})
        target_link_libraries(${UNITY_TARGET}.${TEST_NAME} ${lib})
        message(STATUS "Unity test '${TEST_NAME}' linked with 'lib${lib}'")
    endforeach()
endfunction()
