#include "godotx_att_module.h"
#include "godotx_att.h"

#include "core/config/engine.h"
#include "core/object/class_db.h"

GodotxATT *godotx_att = nullptr;

void initialize_godotx_att_module() {
    godotx_att = memnew(GodotxATT);
    Engine::get_singleton()->add_singleton(Engine::Singleton("GodotxATT", godotx_att));
}

void uninitialize_godotx_att_module() {
    if (godotx_att) {
        memdelete(godotx_att);
        godotx_att = nullptr;
    }
}
