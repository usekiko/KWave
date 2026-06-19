(function () {
    let MenuTpl =
        '<div id="menu_{{_namespace}}_{{_name}}" class="dialog {{#isBig}}big{{/isBig}}">' +
        '<div class="head"><span>{{title}}</span></div>' +
        '{{#isDefault}}<input type="text" name="value" id="inputText"/>{{/isDefault}}' +
        '{{#isBig}}<textarea name="value"/>{{/isBig}}' +
        '<button type="button" name="submit">Submit</button>' +
        '<button type="button" name="cancel">Cancel</button>' +
        "</div>" +
        "</div>";
    window.KW_MENU = {};
    KW_MENU.ResourceName = "kw_menu_dialog";
    KW_MENU.opened = {};
    KW_MENU.focus = [];
    KW_MENU.pos = {};

    KW_MENU.open = function (namespace, name, data) {
        if (typeof KW_MENU.opened[namespace] === "undefined") {
            KW_MENU.opened[namespace] = {};
        }

        if (typeof KW_MENU.opened[namespace][name] != "undefined") {
            KW_MENU.close(namespace, name);
        }

        if (typeof KW_MENU.pos[namespace] === "undefined") {
            KW_MENU.pos[namespace] = {};
        }

        if (typeof data.type === "undefined") {
            data.type = "default";
        }

        if (typeof data.align === "undefined") {
            data.align = "top-left";
        }

        data._index = KW_MENU.focus.length;
        data._namespace = namespace;
        data._name = name;

        KW_MENU.opened[namespace][name] = data;
        KW_MENU.pos[namespace][name] = 0;

        KW_MENU.focus.push({
            namespace: namespace,
            name: name,
        });

        document.onkeyup = function (key) {
            if (key.which === 27) {
                // Escape key
                SendMessage(KW_MENU.ResourceName, "menu_cancel", data);
            } else if (key.which === 13) {
                // Enter key
                SendMessage(KW_MENU.ResourceName, "menu_submit", data);
            }
        };

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
        let menuContainer = $("#menus")[0];
        $(menuContainer).find('button[name="submit"]').unbind("click");
        $(menuContainer).find('button[name="cancel"]').unbind("click");
        $(menuContainer).find('[name="value"]').unbind("input propertychange");
        menuContainer.innerHTML = "";
        $(menuContainer).hide();

        for (let namespace in KW_MENU.opened) {
            for (let name in KW_MENU.opened[namespace]) {
                let menuData = KW_MENU.opened[namespace][name];
                let view = JSON.parse(JSON.stringify(menuData));

                switch (menuData.type) {
                    case "default": {
                        view.isDefault = true;
                        break;
                    }

                    case "big": {
                        view.isBig = true;
                        break;
                    }

                    default:
                        break;
                }

                let menu = $(Mustache.render(MenuTpl, view))[0];

                $(menu).css("z-index", 1000 + view._index);

                $(menu)
                    .find('button[name="submit"]')
                    .click(
                        function () {
                            KW_MENU.submit(this.namespace, this.name, this.data);
                        }.bind({ namespace: namespace, name: name, data: menuData })
                    );

                $(menu)
                    .find('button[name="cancel"]')
                    .click(
                        function () {
                            KW_MENU.cancel(this.namespace, this.name, this.data);
                        }.bind({ namespace: namespace, name: name, data: menuData })
                    );

                $(menu)
                    .find('[name="value"]')
                    .bind(
                        "input propertychange",
                        function () {
                            this.data.value = $(menu).find('[name="value"]').val();
                            KW_MENU.change(this.namespace, this.name, this.data);
                        }.bind({ namespace: namespace, name: name, data: menuData })
                    );

                if (typeof menuData.value != "undefined") {
                    $(menu).find('[name="value"]').val(menuData.value);
                }

                menuContainer.appendChild(menu);
            }
        }

        $(menuContainer).show();
        $("#inputText").focus();
    };

    KW_MENU.submit = function (namespace, name, data) {
        SendMessage(KW_MENU.ResourceName, "menu_submit", data);
    };

    KW_MENU.cancel = function (namespace, name, data) {
        SendMessage(KW_MENU.ResourceName, "menu_cancel", data);
    };

    KW_MENU.change = function (namespace, name, data) {
        SendMessage(KW_MENU.ResourceName, "menu_change", data);
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
})();
