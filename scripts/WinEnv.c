// Configs to load monitor, layout and workspaces for my Windows environment
#pragma once
#include "json.hpp"
#include <codecvt>
#include <locale>
#include <memory>
#ifndef NLOHMANN_OPT_HELPER
#define NLOHMANN_OPT_HELPER
namespace nlohmann {
    template <typename T>
    struct adl_serializer<std::shared_ptr<T>> {
        static void to_json(json & j, const std::shared_ptr<T> & opt) {
            if (!opt) j = nullptr; else j = *opt;
        }

        static std::shared_ptr<T> from_json(const json & j) {
            if (j.is_null()) return std::make_shared<T>(); else return std::make_shared<T>(j.get<T>());
        }
    };
    template <typename T>
    struct adl_serializer<boost::optional<T>> {
        static void to_json(json & j, const boost::optional<T> & opt) {
            if (!opt) j = nullptr; else j = *opt;
        }

        static boost::optional<T> from_json(const json & j) {
            if (j.is_null()) return boost::optional<T>(); else return boost::optional<T>(j.get<T>());
        }
    };
}
#endif

namespace MyWinEnv {
    using nlohmann::json;

    template<typename T>
    struct tag {};

    template<typename fromType, typename toType>
    class Utf16_Utf8 {
        private:
        template<typename TF, typename TT>
        static toType convert(tag<std::shared_ptr<TF> >, tag<std::shared_ptr<TT> >, fromType ptr) {
            if (ptr == nullptr) return std::unique_ptr<TT>(); else return std::unique_ptr<TT>(new TT(Utf16_Utf8<TF,TT>::convert(*ptr)));
        }

        template<typename TF, typename TT>
        static toType convert(tag<std::vector<TF> >, tag<std::vector<TT> >, fromType v) {
            auto it = v.begin();
            auto newVector = std::vector<TT>();
            while (it != v.end()) {
                newVector.push_back(Utf16_Utf8<TF,TT>::convert(*it));
                it++;
            }
            return newVector;
        }

        template<typename KF, typename VF, typename KT, typename VT>
        static toType convert(tag<std::map<KF,VF> >, tag<std::map<KT,VT> >, fromType m) {
            auto it = m.begin();
            auto newMap = std::map<KT, VT>();
            while (it != m.end()) {
                newMap.insert(std::pair<KT, VT>(Utf16_Utf8<KF, KT>::convert(it->first), Utf16_Utf8<VF, VT>::convert(it->second)));
                it++;
            }
            return newMap;
        }

        template<typename TF, typename TT>
        static fromType convert(tag<TF>, tag<TT>, fromType from) {
            return from;
        }

        static std::wstring convert(tag<std::string>, tag<std::wstring>, std::string str) {
            return std::wstring_convert<std::codecvt_utf8_utf16<wchar_t, 0x10ffff, std::little_endian>, wchar_t>{}.from_bytes(str.data());
        }

        static std::string convert(tag<std::wstring>, tag<std::string>, std::wstring str) {
            return std::wstring_convert<std::codecvt_utf8_utf16<wchar_t, 0x10ffff, std::little_endian>, wchar_t>{}.to_bytes(str.data());
        }

        public:
        static toType convert(fromType in) {
            return convert(tag<fromType>(), tag<toType>(), in);
        }
    };

    template<typename T>
    std::wstring wdump(const T& j) {
        std::ostringstream s;
        s << j;
        return Utf16_Utf8<std::string, std::wstring>::convert(s.str()); 
    }

    #ifndef NLOHMANN_UNTYPED_MyWinEnv_HELPER
    #define NLOHMANN_UNTYPED_MyWinEnv_HELPER
    inline json get_untyped(const json & j, const char * property) {
        if (j.find(property) != j.end()) {
            return j.at(property).get<json>();
        }
        return json();
    }

    inline json get_untyped(const json & j, std::string property) {
        return get_untyped(j, property.data());
    }
    #endif

    #ifndef NLOHMANN_OPTIONAL_MyWinEnv_HELPER
    #define NLOHMANN_OPTIONAL_MyWinEnv_HELPER
    template <typename T>
    inline std::shared_ptr<T> get_heap_optional(const json & j, const char * property) {
        auto it = j.find(property);
        if (it != j.end() && !it->is_null()) {
            return j.at(property).get<std::shared_ptr<T>>();
        }
        return std::shared_ptr<T>();
    }

    template <typename T>
    inline std::shared_ptr<T> get_heap_optional(const json & j, std::string property) {
        return get_heap_optional<T>(j, property.data());
    }
    template <typename T>
    inline boost::optional<T> get_stack_optional(const json & j, const char * property) {
        auto it = j.find(property);
        if (it != j.end() && !it->is_null()) {
            return j.at(property).get<boost::optional<T>>();
        }
        return boost::optional<T>();
    }

    template <typename T>
    inline boost::optional<T> get_stack_optional(const json & j, std::string property) {
        return get_stack_optional<T>(j, property.data());
    }
    #endif

    struct InvisibleBorders {
        int64_t left;
        int64_t top;
        int64_t right;
        int64_t bottom;
    };

    struct WindowsElement {
        int64_t hwnd;
        std::wstring title;
        std::wstring exe;
        std::wstring element_class;
        InvisibleBorders rect;
    };

    struct Windows {
        std::vector<WindowsElement> elements;
        int64_t focused;
    };

    struct ContainersElement {
        Windows windows;
    };

    struct Containers {
        std::vector<ContainersElement> elements;
        int64_t focused;
    };

    struct Layout {
        std::wstring layout_default;
    };

    struct WorkspacesElement {
        boost::optional<std::wstring> name;
        Containers containers;
        nlohmann::json monocle_container;
        nlohmann::json maximized_window;
        std::vector<nlohmann::json> floating_windows;
        Layout layout;
        std::vector<nlohmann::json> layout_rules;
        nlohmann::json layout_flip;
        int64_t workspace_padding;
        int64_t container_padding;
        std::vector<nlohmann::json> resize_dimensions;
        bool tile;
    };

    struct Workspaces {
        std::vector<WorkspacesElement> elements;
        int64_t focused;
    };

    struct MonitorsElement {
        int64_t id;
        std::wstring name;
        InvisibleBorders size;
        InvisibleBorders work_area_size;
        nlohmann::json work_area_offset;
        Workspaces workspaces;
    };

    struct Monitors {
        std::vector<MonitorsElement> elements;
        int64_t focused;
    };

    struct Config {
        Monitors monitors;
        bool is_paused;
        InvisibleBorders invisible_borders;
        int64_t resize_delta;
        std::wstring new_window_behaviour;
        std::wstring cross_monitor_move_behaviour;
        nlohmann::json work_area_offset;
        std::wstring focus_follows_mouse;
        bool mouse_follows_focus;
        bool has_pending_raise_op;
        bool remove_titlebars;
        std::vector<std::wstring> float_identifiers;
        std::vector<std::wstring> manage_identifiers;
        std::vector<std::wstring> layered_whitelist;
        std::vector<std::wstring> tray_and_multi_window_identifiers;
        std::vector<std::wstring> border_overflow_identifiers;
        std::vector<std::wstring> name_change_on_launch_identifiers;
    };
}

namespace MyWinEnv {
    void from_json(const json & j, InvisibleBorders & x);
    void to_json(json & j, const InvisibleBorders & x);

    void from_json(const json & j, WindowsElement & x);
    void to_json(json & j, const WindowsElement & x);

    void from_json(const json & j, Windows & x);
    void to_json(json & j, const Windows & x);

    void from_json(const json & j, ContainersElement & x);
    void to_json(json & j, const ContainersElement & x);

    void from_json(const json & j, Containers & x);
    void to_json(json & j, const Containers & x);

    void from_json(const json & j, Layout & x);
    void to_json(json & j, const Layout & x);

    void from_json(const json & j, WorkspacesElement & x);
    void to_json(json & j, const WorkspacesElement & x);

    void from_json(const json & j, Workspaces & x);
    void to_json(json & j, const Workspaces & x);

    void from_json(const json & j, MonitorsElement & x);
    void to_json(json & j, const MonitorsElement & x);

    void from_json(const json & j, Monitors & x);
    void to_json(json & j, const Monitors & x);

    void from_json(const json & j, Welcome & x);
    void to_json(json & j, const Welcome & x);

    inline void from_json(const json & j, InvisibleBorders& x) {
        x.left = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"left")).get<int64_t>();
        x.top = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"top")).get<int64_t>();
        x.right = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"right")).get<int64_t>();
        x.bottom = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"bottom")).get<int64_t>();
    }

    inline void to_json(json & j, const InvisibleBorders & x) {
        j = json::object();
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"left")] = x.left;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"top")] = x.top;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"right")] = x.right;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"bottom")] = x.bottom;
    }

    inline void from_json(const json & j, WindowsElement& x) {
        x.hwnd = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"hwnd")).get<int64_t>();
        x.title = Utf16_Utf8<std::string, std::wstring>::convert(j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"title")).get<std::string>());
        x.exe = Utf16_Utf8<std::string, std::wstring>::convert(j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"exe")).get<std::string>());
        x.element_class = Utf16_Utf8<std::string, std::wstring>::convert(j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"class")).get<std::string>());
        x.rect = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"rect")).get<InvisibleBorders>();
    }

    inline void to_json(json & j, const WindowsElement & x) {
        j = json::object();
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"hwnd")] = x.hwnd;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"title")] = Utf16_Utf8<std::wstring, std::string>::convert(x.title);
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"exe")] = Utf16_Utf8<std::wstring, std::string>::convert(x.exe);
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"class")] = Utf16_Utf8<std::wstring, std::string>::convert(x.element_class);
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"rect")] = x.rect;
    }

    inline void from_json(const json & j, Windows& x) {
        x.elements = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"elements")).get<std::vector<WindowsElement>>();
        x.focused = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"focused")).get<int64_t>();
    }

    inline void to_json(json & j, const Windows & x) {
        j = json::object();
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"elements")] = x.elements;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"focused")] = x.focused;
    }

    inline void from_json(const json & j, ContainersElement& x) {
        x.windows = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"windows")).get<Windows>();
    }

    inline void to_json(json & j, const ContainersElement & x) {
        j = json::object();
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"windows")] = x.windows;
    }

    inline void from_json(const json & j, Containers& x) {
        x.elements = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"elements")).get<std::vector<ContainersElement>>();
        x.focused = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"focused")).get<int64_t>();
    }

    inline void to_json(json & j, const Containers & x) {
        j = json::object();
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"elements")] = x.elements;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"focused")] = x.focused;
    }

    inline void from_json(const json & j, Layout& x) {
        x.layout_default = Utf16_Utf8<std::string, std::wstring>::convert(j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"Default")).get<std::string>());
    }

    inline void to_json(json & j, const Layout & x) {
        j = json::object();
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"Default")] = Utf16_Utf8<std::wstring, std::string>::convert(x.layout_default);
    }

    inline void from_json(const json & j, WorkspacesElement& x) {
        x.name = Utf16_Utf8<boost::optional<std::string>, boost::optional<std::wstring>>::convert(get_stack_optional<std::string>(j, Utf16_Utf8<std::wstring, std::string>::convert(L"name")));
        x.containers = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"containers")).get<Containers>();
        x.monocle_container = get_untyped(j, Utf16_Utf8<std::wstring, std::string>::convert(L"monocle_container"));
        x.maximized_window = get_untyped(j, Utf16_Utf8<std::wstring, std::string>::convert(L"maximized_window"));
        x.floating_windows = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"floating_windows")).get<std::vector<nlohmann::json>>();
        x.layout = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"layout")).get<Layout>();
        x.layout_rules = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"layout_rules")).get<std::vector<nlohmann::json>>();
        x.layout_flip = get_untyped(j, Utf16_Utf8<std::wstring, std::string>::convert(L"layout_flip"));
        x.workspace_padding = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"workspace_padding")).get<int64_t>();
        x.container_padding = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"container_padding")).get<int64_t>();
        x.resize_dimensions = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"resize_dimensions")).get<std::vector<nlohmann::json>>();
        x.tile = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"tile")).get<bool>();
    }

    inline void to_json(json & j, const WorkspacesElement & x) {
        j = json::object();
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"name")] = Utf16_Utf8<boost::optional<std::wstring>, boost::optional<std::string>>::convert(x.name);
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"containers")] = x.containers;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"monocle_container")] = x.monocle_container;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"maximized_window")] = x.maximized_window;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"floating_windows")] = x.floating_windows;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"layout")] = x.layout;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"layout_rules")] = x.layout_rules;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"layout_flip")] = x.layout_flip;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"workspace_padding")] = x.workspace_padding;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"container_padding")] = x.container_padding;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"resize_dimensions")] = x.resize_dimensions;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"tile")] = x.tile;
    }

    inline void from_json(const json & j, Workspaces& x) {
        x.elements = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"elements")).get<std::vector<WorkspacesElement>>();
        x.focused = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"focused")).get<int64_t>();
    }

    inline void to_json(json & j, const Workspaces & x) {
        j = json::object();
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"elements")] = x.elements;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"focused")] = x.focused;
    }

    inline void from_json(const json & j, MonitorsElement& x) {
        x.id = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"id")).get<int64_t>();
        x.name = Utf16_Utf8<std::string, std::wstring>::convert(j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"name")).get<std::string>());
        x.size = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"size")).get<InvisibleBorders>();
        x.work_area_size = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"work_area_size")).get<InvisibleBorders>();
        x.work_area_offset = get_untyped(j, Utf16_Utf8<std::wstring, std::string>::convert(L"work_area_offset"));
        x.workspaces = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"workspaces")).get<Workspaces>();
    }

    inline void to_json(json & j, const MonitorsElement & x) {
        j = json::object();
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"id")] = x.id;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"name")] = Utf16_Utf8<std::wstring, std::string>::convert(x.name);
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"size")] = x.size;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"work_area_size")] = x.work_area_size;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"work_area_offset")] = x.work_area_offset;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"workspaces")] = x.workspaces;
    }

    inline void from_json(const json & j, Monitors& x) {
        x.elements = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"elements")).get<std::vector<MonitorsElement>>();
        x.focused = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"focused")).get<int64_t>();
    }

    inline void to_json(json & j, const Monitors & x) {
        j = json::object();
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"elements")] = x.elements;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"focused")] = x.focused;
    }

    inline void from_json(const json & j, Welcome& x) {
        x.monitors = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"monitors")).get<Monitors>();
        x.is_paused = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"is_paused")).get<bool>();
        x.invisible_borders = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"invisible_borders")).get<InvisibleBorders>();
        x.resize_delta = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"resize_delta")).get<int64_t>();
        x.new_window_behaviour = Utf16_Utf8<std::string, std::wstring>::convert(j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"new_window_behaviour")).get<std::string>());
        x.cross_monitor_move_behaviour = Utf16_Utf8<std::string, std::wstring>::convert(j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"cross_monitor_move_behaviour")).get<std::string>());
        x.work_area_offset = get_untyped(j, Utf16_Utf8<std::wstring, std::string>::convert(L"work_area_offset"));
        x.focus_follows_mouse = Utf16_Utf8<std::string, std::wstring>::convert(j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"focus_follows_mouse")).get<std::string>());
        x.mouse_follows_focus = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"mouse_follows_focus")).get<bool>();
        x.has_pending_raise_op = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"has_pending_raise_op")).get<bool>();
        x.remove_titlebars = j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"remove_titlebars")).get<bool>();
        x.float_identifiers = Utf16_Utf8<std::vector<std::string>, std::vector<std::wstring>>::convert(j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"float_identifiers")).get<std::vector<std::string>>());
        x.manage_identifiers = Utf16_Utf8<std::vector<std::string>, std::vector<std::wstring>>::convert(j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"manage_identifiers")).get<std::vector<std::string>>());
        x.layered_whitelist = Utf16_Utf8<std::vector<std::string>, std::vector<std::wstring>>::convert(j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"layered_whitelist")).get<std::vector<std::string>>());
        x.tray_and_multi_window_identifiers = Utf16_Utf8<std::vector<std::string>, std::vector<std::wstring>>::convert(j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"tray_and_multi_window_identifiers")).get<std::vector<std::string>>());
        x.border_overflow_identifiers = Utf16_Utf8<std::vector<std::string>, std::vector<std::wstring>>::convert(j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"border_overflow_identifiers")).get<std::vector<std::string>>());
        x.name_change_on_launch_identifiers = Utf16_Utf8<std::vector<std::string>, std::vector<std::wstring>>::convert(j.at(Utf16_Utf8<std::wstring, std::string>::convert(L"name_change_on_launch_identifiers")).get<std::vector<std::string>>());
    }

    inline void to_json(json & j, const Welcome & x) {
        j = json::object();
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"monitors")] = x.monitors;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"is_paused")] = x.is_paused;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"invisible_borders")] = x.invisible_borders;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"resize_delta")] = x.resize_delta;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"new_window_behaviour")] = Utf16_Utf8<std::wstring, std::string>::convert(x.new_window_behaviour);
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"cross_monitor_move_behaviour")] = Utf16_Utf8<std::wstring, std::string>::convert(x.cross_monitor_move_behaviour);
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"work_area_offset")] = x.work_area_offset;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"focus_follows_mouse")] = Utf16_Utf8<std::wstring, std::string>::convert(x.focus_follows_mouse);
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"mouse_follows_focus")] = x.mouse_follows_focus;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"has_pending_raise_op")] = x.has_pending_raise_op;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"remove_titlebars")] = x.remove_titlebars;
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"float_identifiers")] = Utf16_Utf8<std::vector<std::wstring>, std::vector<std::string>>::convert(x.float_identifiers);
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"manage_identifiers")] = Utf16_Utf8<std::vector<std::wstring>, std::vector<std::string>>::convert(x.manage_identifiers);
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"layered_whitelist")] = Utf16_Utf8<std::vector<std::wstring>, std::vector<std::string>>::convert(x.layered_whitelist);
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"tray_and_multi_window_identifiers")] = Utf16_Utf8<std::vector<std::wstring>, std::vector<std::string>>::convert(x.tray_and_multi_window_identifiers);
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"border_overflow_identifiers")] = Utf16_Utf8<std::vector<std::wstring>, std::vector<std::string>>::convert(x.border_overflow_identifiers);
        j[Utf16_Utf8<std::wstring, std::string>::convert(L"name_change_on_launch_identifiers")] = Utf16_Utf8<std::vector<std::wstring>, std::vector<std::string>>::convert(x.name_change_on_launch_identifiers);
    }
}
