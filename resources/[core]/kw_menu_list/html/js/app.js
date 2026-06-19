(function () {
    let MenuTpl =
        '<div id="menu_{{_namespace}}_{{_name}}" class="menu">' +
        "<table>" +
        "<thead>" +
        "<tr>" +
        "{{#head}}<td>{{content}}</td>{{/head}}" +
        "</tr>" +
        "</thead>" +
        "<tbody>" +
        "{{#rows}}" +
        "<tr>" +
        "{{#cols}}<td>{{{content}}}</td>{{/cols}}" +
        "</tr>" +
        "{{/rows}}" +
        "</tbody>" +
        "</table>" +
        "</div>";
    window.KW_MENU = {};
    KW_MENU.ResourceName = "kw_menu_list";
    KW_MENU.opened = {};
    KW_MENU.focus = [];
    KW_MENU.data = {};

    KW_MENU.open = function (namespace, name, data) {
        if (typeof KW_MENU.opened[namespace] === "undefined") {
            KW_MENU.opened[namespace] = {};
        }

        if (typeof KW_MENU.opened[namespace][name] != "undefined") {
            KW_MENU.close(namespace, name);
        }

        data._namespace = namespace;
        data._name = name;

        KW_MENU.opened[namespace][name] = data;

        KW_MENU.focus.push({
            namespace: namespace,
            name: name,
        });

        KW_MENU.render();
    };

    KW_MENU.close = function (namespace, name) {
        delete KW_MENU.opened[namespace][name];

        for (let i = 0; i < KW_MENU.focus.length; i++) {
            if (KW_MENU.focus[i].namespace === namespace && KW_MENU.focus[i].name === name) {
                KW_MENU.focus.splice(i, 1);
                break;
            }
        }

        KW_MENU.render();
    };

    KW_MENU.render = function () {
        let menuContainer = document.getElementById("menus");
        let focused = KW_MENU.getFocused();
        menuContainer.innerHTML = "";

        $(menuContainer).hide();

        for (let namespace in KW_MENU.opened) {
            if (typeof KW_MENU.data[namespace] === "undefined") {
                KW_MENU.data[namespace] = {};
            }

            for (let name in KW_MENU.opened[namespace]) {
                KW_MENU.data[namespace][name] = [];

                let menuData = KW_MENU.opened[namespace][name];
                let view = {
                    _namespace: menuData._namespace,
                    _name: menuData._name,
                    head: [],
                    rows: [],
                };

                for (let i = 0; i < menuData.head.length; i++) {
                    let item = { content: menuData.head[i] };
                    view.head.push(item);
                }

                for (let i = 0; i < menuData.rows.length; i++) {
                    let row = menuData.rows[i];
                    let data = row.data;

                    KW_MENU.data[namespace][name].push(data);

                    view.rows.push({ cols: [] });

                    for (let j = 0; j < row.cols.length; j++) {
                        let col = menuData.rows[i].cols[j];
                        let regex = /\{\{(.*?)\|(.*?)\}\}/g;
                        let matches = [];
                        let match;

                        while ((match = regex.exec(col)) != null) {
                            matches.push(match);
                        }

                        for (let k = 0; k < matches.length; k++) {
                            col = col.replace("{{" + matches[k][1] + "|" + matches[k][2] + "}}", '<button data-id="' + i + '" data-namespace="' + namespace + '" data-name="' + name + '" data-value="' + matches[k][2] + '">' + matches[k][1] + "</button>");
                        }

                        view.rows[i].cols.push({ data: data, content: col });
                    }
                }

                let menu = $(Mustache.render(MenuTpl, view));

                menu.find("button[data-namespace][data-name]").click(function () {
                    KW_MENU.data[$(this).data("namespace")][$(this).data("name")][parseInt($(this).data("id"))].currentRow = parseInt($(this).data("id")) + 1;
                    KW_MENU.submit($(this).data("namespace"), $(this).data("name"), {
                        data: KW_MENU.data[$(this).data("namespace")][$(this).data("name")][parseInt($(this).data("id"))],
                        value: $(this).data("value"),
                    });
                });

                menu.hide();

                menuContainer.appendChild(menu[0]);
            }
        }

        if (typeof focused != "undefined") {
            $("#menu_" + focused.namespace + "_" + focused.name).show();
        }

        $(menuContainer).show();
    };

    KW_MENU.submit = function (namespace, name, data) {
        $.post(
            "http://" + KW_MENU.ResourceName + "/menu_submit",
            JSON.stringify({
                _namespace: namespace,
                _name: name,
                data: data.data,
                value: data.value,
            })
        );
    };

    KW_MENU.cancel = function (namespace, name) {
        $.post(
            "http://" + KW_MENU.ResourceName + "/menu_cancel",
            JSON.stringify({
                _namespace: namespace,
                _name: name,
            })
        );
    };

    KW_MENU.getFocused = function () {
        return KW_MENU.focus[KW_MENU.focus.length - 1];
    };

    window.onData = (data) => {
        switch (data.action) {
            case "openMenu": {
                KW_MENU.open(data.namespace, data.name, data.data);
                break;
            }

            case "closeMenu": {
                KW_MENU.close(data.namespace, data.name);
                break;
            }
        }
    };

    window.onload = function (e) {
        window.addEventListener("message", (event) => {
            onData(event.data);
        });
    };

    document.onkeyup = function (data) {
        if (data.which === 27) {
            let focused = KW_MENU.getFocused();
            KW_MENU.cancel(focused.namespace, focused.name);
        }
    };
})();
