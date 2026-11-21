#include <ntqapplication.h>
#include <tqca.h>
#include <stdio.h>

int main(int argc, char **argv)
{
    TQApplication app(argc, argv, false);
    TQCA::init();
    bool tls = TQCA::isSupported(TQCA::CAP_TLS);
    printf("TQCA TLS provider: %s\n", tls ? "OK" : "not available");
    return tls ? 0 : 1;
}
