{pkgs, ...}: {
  # Installs the Java Development Kit required by Flutter/Gradle
  packages = [
    pkgs.jdk17
  ];

  # Automatically points Flutter to the newly installed Java package
  env = {
    JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";
  };

  # Enable previews and customize configuration
  idx.previews = {
    enable = true;
    previews = {
      # The following object sets web previews
      # web = {
      #  command = [
      #    "npm"
      #    "run"
      #    "start"
      #    "--"
      #    "--port"
      #    "$PORT"
      #    "--host"
      #    "0.0.0.0"
      #    "--disable-host-check"
      #  ];
      #  manager = "web";
        # Optionally, specify a directory that contains your web app
        # cwd = "app/client";
      #};
      # The following object sets Android previews
      # Note that this is supported only on Flutter workspaces
      android = {
        manager = "flutter";
      };
    };
  };
}