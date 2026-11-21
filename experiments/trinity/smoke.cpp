#include <ntqapplication.h>
#include <ntqimage.h>
#include <ntqstring.h>
#include <ntqthread.h>
#include <ntqtimer.h>
#include <stdio.h>

class Worker : public TQThread {
public:
    int result;
    Worker() : result(0) {}
    void run() { result = 42; }
};

int main(int argc, char **argv)
{
    TQApplication app(argc, argv, false);
    TQString text = TQString::fromUtf8("MabOs: áéíóú — TQt");
    if (TQString::fromUtf8(text.utf8()) != text)
        return 1;
    Worker worker;
    worker.start();
    if (!worker.wait(5000) || worker.result != 42)
        return 2;
    TQImage image(8, 8, 32);
    image.fill(0xff356b51);
    if (!image.save("/work/.work/trinity/smoke.png", "PNG"))
        return 3;
    TQImage loaded("/work/.work/trinity/smoke.png");
    if (loaded.isNull() || loaded.width() != 8 ||
        loaded.pixel(0, 0) != image.pixel(0, 0))
        return 4;
    TQTimer::singleShot(20, &app, TQ_SLOT(quit()));
    int result = app.exec();
    printf("TQt %s: UTF-8, thread, PNG and event loop OK\n", tqVersion());
    return result;
}
