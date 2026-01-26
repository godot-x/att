#ifndef GODOTX_ATT_H
#define GODOTX_ATT_H

#include "core/object/class_db.h"
#include "core/variant/variant.h"

class GodotxATT : public Object {
    GDCLASS(GodotxATT, Object);

protected:
    static void _bind_methods();

public:
    static GodotxATT *instance;
    static GodotxATT *get_singleton();

    void request_permission();
    int get_status();
    String get_status_string();

    GodotxATT();
    ~GodotxATT();
};

#endif
