/****************************************************************************
** Generated QML type registration code
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include <QtQml/qqml.h>
#include <QtQml/qqmlmoduleregistration.h>

#if __has_include(<blobgroup.hpp>)
#  include <blobgroup.hpp>
#endif
#if __has_include(<blobinvertedrect.hpp>)
#  include <blobinvertedrect.hpp>
#endif
#if __has_include(<blobrect.hpp>)
#  include <blobrect.hpp>
#endif


#if !defined(QT_STATIC)
#define Q_QMLTYPE_EXPORT Q_DECL_EXPORT
#else
#define Q_QMLTYPE_EXPORT
#endif
Q_QMLTYPE_EXPORT void qml_register_types_Caelestia_Blobs()
{
    QT_WARNING_PUSH QT_WARNING_DISABLE_DEPRECATED
    qmlRegisterTypesAndRevisions<BlobGroup>("Caelestia.Blobs", 1);
    qmlRegisterTypesAndRevisions<BlobInvertedRect>("Caelestia.Blobs", 1);
    qmlRegisterAnonymousType<QQuickItem, 254>("Caelestia.Blobs", 1);
    qmlRegisterTypesAndRevisions<BlobRect>("Caelestia.Blobs", 1);
    QMetaType::fromType<BlobShape *>().id();
    QT_WARNING_POP
    qmlRegisterModule("Caelestia.Blobs", 1, 0);
}

static const QQmlModuleRegistration caelestiaBlobsRegistration("Caelestia.Blobs", qml_register_types_Caelestia_Blobs);
