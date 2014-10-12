<!DOCTYPE html>
<html lang="de">

<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Freifunk <%= @city_name %> - fastd Key eintragen</title>

    <link rel="stylesheet" type="text/css" href="css/style.css" />
    <link rel="stylesheet" type="text/css" href="css/bootstrap.min.css" />
    <script src="js/jquery-1.8.3.min.js"></script>
    <script src="js/bootstrap.min.js"></script>

    <script>
        var validationMessages = {
            key: "Der angegebene VPN-Schlüssel ist ungültig.",
            hostname: "Knotennamen dürfen maximal 32 Zeichen lang sein und nur Klein- und Großbuchstaben, sowie Ziffern, - und _ enthalten."
        };

        function feedback(cls, msg) {
            var html = "";
            html += "<div class=\"alert " + cls + "\">";
            html += msg;
            html += "<a class=\"close\" data-dismiss=\"alert\" href=\"#\">&times;</a>";
            html += "</div>";

            var div = $(html);
            $("#feedback").append(div);
        }

        function clearFeedback() {
            $("#feedback").empty();
        }

        function success(msg) {
            feedback("alert-success", msg);
            $("form")[0].reset();            
        }

        function error(msg) {
            feedback("alert-danger", msg);
        }

        function updateValidationErrors(fields) {
            $(".form-group.has-error").toggleClass("has-error", false);
            $(".form-group .feedback").empty();

            for (var i = 0; i < fields.length; i++) {
                var field = fields[i];
                $(".form-group." + field).toggleClass("has-error", true);
                $(".form-group." + field + " .feedback").text(validationMessages[field]);
            }
        }

        function handleSubmit(e) {
            if (e) {
                e.preventDefault();
            }

            clearFeedback();
            updateValidationErrors([]);

            var hostname = $("input[name=hostname]").val();
            var key = $("input[name=key]").val();

            $.ajax("/api/node", {
                type: "POST",
                data: {
                    hostname: hostname,
                    key: key,
                },
                success: function () {
                    success("Glückwunsch, der Knoten ist jetzt angemeldet!");
                },
                error: function (jqxhr) {
                    var result = JSON.parse(jqxhr.responseText);

                    switch (result.type) {
                        case "ValidationError":
                            updateValidationErrors(result.validationResult.missing.concat(result.validationResult.invalid));
                        break;
                        case "NodeEntryAlreadyExistsError":
                            error("Für den Knoten " + result.hostname + " existiert bereits ein Eintrag.");
                        break;
                        default:
                            error("Es ist ein unerwarteter Fehler aufgetreten.");
                    }
                }
            });

            return false;
        }

        $(document).ready(function () {
            $("form button[type='submit'],form input[type='text']").removeAttr("disabled");
            $("form").submit(handleSubmit);
        });
    </script>

</head>

<body>
    <div class="navbar navbar-default navbar-fixed-top">
      <div class="container">
        <div class="navbar-header">
          <a class="navbar-brand" href="<%= @community_url.downcase %>">Freifunk <%= @city_name %></a>
        </div>
      </div>
    </div>

    <div class="container">
        <h1>Knoten anmelden</h1>

        <p>
          Du hast deinen Router erfolgreich mit der Freifunk <%= @city_name %>
          Firmware geflashed und möchtest ihn nun über das Internet mit dem
          Freifunknetz verbinden?  Dann trage bitte den Namen deines Routers und
          den VPN-Key (beides wurde dir nach dem Einrichten des Routers
          angezeigt) in das folgende Formular ein.
        </p>

        <p>
          Nach dem Eintragen verbindet sich der Router innerhalb der nächsten 5 Minuten mit dem Freifunknetz.
        </p>

        <div class="container well">
            <noscript>
                <div class="alert alert-danger">
                    <h4>Achtung!</h4>
                    Du hast kein JavaScript aktiviert oder dein Browser unterstützt kein
                    JavaScript. Bitte aktiviere JavaScript oder nutze einen anderen Browser,
                    um deinen Freifunk-Knoten registrieren zu können.
                </div>
            </noscript>

            <form method="post" role="form">
                <div id="feedback"></div>
                <fieldset>
                    <div class="form-group hostname">
                        <label class="control-label" for="hostname">Knotenname</label>
                        <input type="text" disabled="disabled" class="form-control" name="hostname" placeholder="Knotenname" />
                        <span class="feedback help-block"></span>
                    </div>
                    <div class="form-group key">
                        <label class="control-label" for="key">VPN-Schlüssel</label>
                        <input type="text" disabled="disabled" class="form-control" name="key" placeholder="VPN-Schlüssel" />
                        <span class="feedback help-block"></span>
                    </div>
                    <button class="btn btn-primary" type="submit" disabled="disabled">
                        <strong>+</strong>
                        Knoten eintragen
                    </button>
                </fieldset>
            </form>
        </div>
    </div>
</body>

</html>

