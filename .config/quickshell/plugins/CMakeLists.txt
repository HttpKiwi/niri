cmake_minimum_required(VERSION 3.16)
project(CaelestiaBlobs LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick Gui ShaderTools)

qt_add_qml_module(caelestia-blobs
    URI Caelestia.Blobs
    VERSION 1.0
    SOURCES
        Caelestia/Blobs/blobgroup.hpp
        Caelestia/Blobs/blobgroup.cpp
        Caelestia/Blobs/blobshape.hpp
        Caelestia/Blobs/blobshape.cpp
        Caelestia/Blobs/blobrect.hpp
        Caelestia/Blobs/blobrect.cpp
        Caelestia/Blobs/blobinvertedrect.hpp
        Caelestia/Blobs/blobinvertedrect.cpp
        Caelestia/Blobs/blobmaterial.hpp
        Caelestia/Blobs/blobmaterial.cpp
)

target_include_directories(caelestia-blobs PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/Caelestia/Blobs)
target_link_libraries(caelestia-blobs PRIVATE Qt::Quick)

qt_add_shaders(caelestia-blobs "blob_shaders"
    BATCHABLE OPTIMIZED NOHLSL NOMSL
    GLSL "300es,330"
    PREFIX "/"
    FILES
        Caelestia/Blobs/shaders/blob.frag
        Caelestia/Blobs/shaders/blob.vert
)
