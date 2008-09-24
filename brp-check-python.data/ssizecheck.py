# $Id$
# look for modified API functions, based on input by MAL and MvL.

# usage: python ssizecheck.py mysources/*.c

# see also: http://www.python.org/dev/peps/pep-0353

import glob, re, os, sys

def check(file):
    for lineno, text in enumerate(open(file)):
        for token in re.findall("\w+", text):
            if token in API_OUTPUT:
                message = "WARNING: %r uses Py_ssize_t for output"\
                          " parameters (must fix!)"
            elif token in API_RETURN:
                message = "%r uses Py_ssize_t for return values"\
                          " (may need overflow check)"
            elif token in API:
                message = "%r uses Py_ssize_t for input parameters"
            elif token in FUNCPTR:
                if token == "inquiry":
                    message = "%%r should be perhaps replaced with %r"
                else:
                    message = "WARNING: %%r must be replaced with %r"
                message = message % FUNCPTR[token]
            else:
                continue
            print "%s:%d: %s" % (file, lineno+1, message % token)

# --------------------------------------------------------------------

# all changed/new APIs (from MAL):

API = set("""
PyBuffer_FromMemory
PyBuffer_FromObject
PyBuffer_FromReadWriteMemory
PyBuffer_FromReadWriteObject
PyBuffer_New
PyDict_Next
PyDict_Size
PyInt_AsSsize_t
PyInt_FromSsize_t
PyInt_FromUnicode
PyList_GetItem
PyList_GetSlice
PyList_Insert
PyList_New
PyList_SetItem
PyList_SetSlice
PyList_Size
PyLong_FromUnicode
PyMapping_Length
PyMapping_Size
PyMarshal_ReadObjectFromString
PyObject_AsCharBuffer
PyObject_AsReadBuffer
PyObject_AsWriteBuffer
PyObject_InitVar
PyObject_Length
PyObject_Size
PySequence_DelItem
PySequence_DelSlice
PySequence_GetItem
PySequence_GetSlice
PySequence_InPlaceRepeat
PySequence_Length
PySequence_Repeat
PySequence_SetItem
PySequence_SetSlice
PySequence_Size
PySlice_GetIndices
PySlice_GetIndicesEx
PyString_AsStringAndSize
PyString_Decode
PyString_DecodeEscape
PyString_Encode
PyString_FromStringAndSize
PyString_Size
PyTuple_GetItem
PyTuple_GetSlice
PyTuple_New
PyTuple_Pack
PyTuple_SetItem
PyTuple_Size
PyType_GenericAlloc
PyUnicodeDecodeError_Create
PyUnicodeDecodeError_GetEnd
PyUnicodeDecodeError_GetStart
PyUnicodeDecodeError_SetEnd
PyUnicodeDecodeError_SetStart
PyUnicodeEncodeError_Create
PyUnicodeEncodeError_GetEnd
PyUnicodeEncodeError_GetStart
PyUnicodeEncodeError_SetEnd
PyUnicodeEncodeError_SetStart
PyUnicodeTranslateError_Create
PyUnicodeTranslateError_GetEnd
PyUnicodeTranslateError_GetStart
PyUnicodeTranslateError_SetEnd
PyUnicodeTranslateError_SetStart
PyUnicode_AsWideChar
PyUnicode_Count
PyUnicode_Decode
PyUnicode_DecodeASCII
PyUnicode_DecodeCharmap
PyUnicode_DecodeLatin1
PyUnicode_DecodeMBCS
PyUnicode_DecodeRawUnicodeEscape
PyUnicode_DecodeUTF16
PyUnicode_DecodeUTF16Stateful
PyUnicode_DecodeUTF7
PyUnicode_DecodeUTF8
PyUnicode_DecodeUTF8Stateful
PyUnicode_DecodeUnicodeEscape
PyUnicode_Encode
PyUnicode_EncodeASCII
PyUnicode_EncodeCharmap
PyUnicode_EncodeDecimal
PyUnicode_EncodeLatin1
PyUnicode_EncodeMBCS
PyUnicode_EncodeRawUnicodeEscape
PyUnicode_EncodeUTF16
PyUnicode_EncodeUTF7
PyUnicode_EncodeUTF8
PyUnicode_EncodeUnicodeEscape
PyUnicode_Find
PyUnicode_FromUnicode
PyUnicode_FromWideChar
PyUnicode_GetSize
PyUnicode_RSplit
PyUnicode_Replace
PyUnicode_Resize
PyUnicode_Split
PyUnicode_Tailmatch
PyUnicode_TranslateCharmap
_PyEval_SliceIndex
_PyLong_AsSsize_t
_PyLong_FromSsize_t
_PyLong_New
_PyObject_GC_NewVar
_PyObject_GC_Resize
_PyObject_LengthHint
_PyObject_NewVar
_PyString_Resize
_PyTuple_Resize
""".split())

# Py_ssize_t output parameters (these MUST be fixed) (from MAL)

API_OUTPUT = set("""
PyDict_Next
PyObject_AsCharBuffer
PyObject_AsReadBuffer
PyObject_AsWriteBuffer
PySlice_GetIndices
PySlice_GetIndicesEx
PyString_AsStringAndSize
PyUnicodeDecodeError_GetEnd
PyUnicodeDecodeError_GetStart
PyUnicodeEncodeError_GetEnd
PyUnicodeEncodeError_GetStart
PyUnicodeTranslateError_GetEnd
PyUnicodeTranslateError_GetStart
PyUnicode_DecodeUTF8Stateful
_PyEval_SliceIndex
""".split())

# Py_ssize_t return values (these may need overflow checks) (from MAL)

API_RETURN = set("""
PyDict_Size
PyInt_AsSsize_t
PyList_Size
PyMapping_Length
PyMapping_Size
PyObject_Length
PyObject_Size
PySequence_Length
PySequence_Size
PyString_Size
PyTuple_Size
PyUnicode_AsWideChar
PyUnicode_Count
PyUnicode_Find
PyUnicode_GetSize
PyUnicode_Tailmatch
_PyLong_AsSsize_t
_PyObject_LengthHint
""".split())

# function pointer types (from MvL)

# note that "inquiry" is still used for some slots (nb_nonzero,
# tp_clear, and tp_is_gc); the others MUST be always be fixed.

FUNCPTR = {
    "intargfunc": "ssizeargfunc",
    "intintargfunc": "ssizessizeargfunc",
    "intobjargproc": "ssizeobjargproc",
    "intintobjargproc": "ssizessizeobjargproc",
    "inquiry": "lenfunc",
    "getreadbufferproc": "readbufferproc",
    "getwritebufferproc": "writebufferproc",
    "getsegcountproc": "segcountproc",
    "getcharbufferproc": "charbufferproc",
}

if __name__ == "__main__":
    for arg in sys.argv[1:]:
        if os.path.isdir(arg):
            arg = os.path.join(arg, "*.c") # assume C
        if glob.has_magic(arg):
            files = glob.glob(arg)
        else:
            files = [arg]
        for file in files:
            check(file)
