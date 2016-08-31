# CMake module to generate Sphinx based documentation.
# 
# For more detials please check http://www.sphinx-doc.org
#
# Copyright (c) 2016 Piotr L. Figlarek
#
# Usage
# -----
# 1. Install Sphinx (for example via 'pip install Sphinx'),
# 2. create documentation config file (for exampla via `sphinx-quickstart`),
# 3. include this module in your project,
# 4. add docymentation target via sphinx_generate_doc(...) function,
# 5. generate documentation via 'make doc' command.
#
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


# target to run cpplint.py for all configured sources
set(SPHINX_TARGET doc CACHE STRING "Name of build documentation target") 


# find Sphinx builder 
find_program(SPHINX_BUILD sphinx-build)
if(NOT SPHINX_BUILD)
    message(FATAL_ERROR "Please install Sphinx")
endif()


# Build documentation from DOC_INPUT directory and save output in DOC_OUTPUT.
# Additionally you can define via optional arguments:
#  - builder type,
#  - version of generated documentation;
#
# for example:
#     sphinx_generate_doc(doc doc/html html 1.2.3)
#
# where:
#  - doc      - is root directory with Sphinx documentation,
#  - doc/html - is output directory for generated documentation,
#  - html     - is Sphinx builder type
#  - 1.2.3    - is version of generated documentation.
function(sphinx_generate_doc DOC_INPUT DOC_OUTPUT)
    # Sphinx configuration file
    get_filename_component(SPHINX_CONF ${DOC_INPUT}/conf.py REALPATH)
    if(NOT EXISTS ${SPHINX_CONF})
        message(FATAL_ERROR "${DOC_INPUT} doesn't contain conf.py file")
        return()
    endif()

    # absolute path to root documentation
    get_filename_component(SPHINX_ROOT ${SPHINX_CONF} DIRECTORY)
    
    # configure type of builder
    if(ARGV2)
        set(DOC_BUILDER -b ${ARGV2})
    endif()
    
    # overwrite version definition
    if(ARGV3)
        set(DOC_VERSION -D version=${ARGV3} -D release=${ARGV3})
    endif()
    
    # perform cpplint check
    add_custom_target(${SPHINX_TARGET}
        COMMAND ${SPHINX_BUILD} ${DOC_BUILDER} ${DOC_VERSION} ${SPHINX_ROOT} ${DOC_OUTPUT}
        COMMENT "Sphinx: Building documentation"
    )
endfunction()
