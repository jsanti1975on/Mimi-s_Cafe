# Cyber_Associate_West

**Practice GitHub account:** ftkzgc8qr8-beep

## File Migration (West Side)
Moving West Side assets into this project:
- index.html
- server.py
- additional files as required

## Hardware Bring-Up
### Dell PowerEdge
- Power on the system
- Spin up the controller node
- Host the IoT Dashboard on this machine

## Punch List
- Finish cable management
- Sort and label IoT devices
- Bag and inventory high-use cables and spare devices
- Position esxi-clients host  
  - Supports the default VLAN

## Final Setup: New Location (IoT Lab / The Den)
- Complete physical cabling
- Configure screened subnet
  - Default VLAN: VLAN 1
- Move esxi-client DNS to VLAN 1
- DHCP configuration
  - No reservation for esxi-client at this time

 # Directory Tree & screenshots
<img width="669" height="660" alt="rm-file" src="https://github.com/user-attachments/assets/47579395-8976-4cc3-b6e0-539d920281de" />

<img width="1934" height="1094" alt="rm-file1" src="https://github.com/user-attachments/assets/8cdb8e96-3043-48ee-ae3b-ffd730a5a0e7" />

<img width="921" height="909" alt="rm-file2" src="https://github.com/user-attachments/assets/054a55db-d4dd-4d10-9067-b666209fa2e4" />

<img width="1237" height="664" alt="rm-file3" src="https://github.com/user-attachments/assets/e4d0934a-3e6d-4af0-a86f-097392d71807" />

# Code to write below {^_^}LOOKFLAG=> Use the logo version not THM
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>East Side Server | IoT Subnet Dashboard</title>
  <style>
    body {
      background-color: #1e1e2e;
      color: #8aff80;
      font-family: 'Segoe UI', sans-serif;
      padding: 20px;
      margin: 0;
    }

    h1 {
      text-align: center;
      margin-bottom: 40px;
      border-bottom: 2px solid #8aff80;
      padding-bottom: 10px;
    }

    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 15px;
    }

    .panel-container {
      position: relative;
    }

    .panel {
      background-color: #2a2a3d;
      padding: 20px;
      border-radius: 10px;
      border: 1px solid #8aff80;
      position: relative;
    }

    .hover-image {
      display: none;
      position: absolute;
      bottom: 110%;
      left: 50%;
      transform: translateX(-50%);
      z-index: 10;
      width: 300px;
      border: 2px solid #8aff80;
      border-radius: 10px;
      background: rgba(30, 30, 46, 0.95);
      padding: 5px;
      box-shadow: 0 4px 10px rgba(0, 255, 100, 0.3);
    }

    .panel-container:hover .hover-image {
      display: block;
      animation: floatIn 0.3s ease-out;
    }

    @keyframes floatIn {
      from {
        opacity: 0;
        transform: translateX(-50%) translateY(10px);
      }
      to {
        opacity: 1;
        transform: translateX(-50%) translateY(0);
      }
    }

    .panel h2 {
      margin-top: 0;
      font-size: 1.2em;
    }

    a.button {
      display: inline-block;
      margin-top: 10px;
      padding: 10px 15px;
      background-color: #8aff80;
      color: #1e1e2e;
      text-decoration: none;
      font-weight: bold;
      border-radius: 6px;
      transition: background-color 0.3s, transform 0.3s;
    }

    a.button:hover {
      background-color: #b6ffb3;
      transform: scale(1.1);
    }

    footer {
      text-align: center;
      margin-top: 40px;
      font-size: 0.9em;
      color: #6aff6a;
    }

    .rss-box {
      margin-top: 50px;
      padding: 30px;
      background-color: #2a2a3d;
      border: 2px solid #8aff80;
      border-radius: 10px;
    }

    .rss-box h2 {
      color: #8aff80;
    }

    .rss-entry {
      margin-bottom: 15px;
    }

    .rss-entry a {
      color: #b6ffb3;
    }

    hr {
      border: 1px solid #555;
    }
  </style>
</head>
<body>
  <div class="badge-container" style="text-align:center; margin-bottom: 10px;">
    <iframe src="https://tryhackme.com/api/v2/badges/public-profile?userPublicId=3596940" style="height:150px;width:300px;"></iframe>
    <br />
    <img src="https://tryhackme-badges.s3.amazonaws.com/Orkid1975.png" alt="Badge" style="margin-top:10px; height:30px;" />
  </div>

  <h1>East Side Server (IoT Subnet)</h1>

  <div class="grid">

    <!-- Orchid Collection -->
    <div class="panel-container">
      <div class="panel">
        <h2>Orchid Collection</h2>
        <p>Photos and documentation of orchids, greenhouse logs, and plant care notes.</p>
        <a href="/orchids/" class="button">View Orchids</a>
      </div>
      <img src="images/orchid.png" alt="Orchid Flower" class="hover-image" />
    </div>

    <!-- Docs -->
    <div class="panel-container">
      <div class="panel">
        <h2>Docs</h2>
        <p>General documentation, research notes, and useful references.</p>
        <a href="/docs/" class="button">Open Docs</a>
      </div>
      <img src="images/docs.png" alt="Docs Icon" class="hover-image" />
    </div>

    <!-- After Work -->
    <div class="panel-container">
      <div class="panel">
        <h2>After Work</h2>
        <p>Personal content, general interests, and IoT subnet sandbox experiments.</p>
        <a href="/after-work/" class="button">Browse</a>
      </div>
      <img src="images/after-work.png" alt="After Work" class="hover-image" />
    </div>

    <!-- Assignments -->
    <div class="panel-container">
      <div class="panel">
        <h2>Assignments</h2>
        <p>Dedicated space for my son’s college assignments and uploads.</p>
        <form enctype="multipart/form-data" method="post" action="/assignments/upload">
          <input type="file" name="file" required />
          <br><br>
          <input type="submit" value="Upload Assignment" style="background:#8aff80;color:#1e1e2e;padding:8px 16px;border:none;border-radius:5px;">
        </form>
        <br/>
        <a href="/assignments/" class="button">View Assignments</a>
      </div>
      <img src="images/assignments.png" alt="Assignments Icon" class="hover-image" />
    </div>

  </div>

  <div class="rss-box">
    <h2>Cybersecurity News Feed</h2>
    <div id="rss-feed" style="font-size: 0.95em; color: #b6ffb3;"></div>
  </div>

  <footer>
    &copy; 2025 East Side IoT Server | Orchids. Docs. Assignments. | jas.digital.tools (c) 2025
  </footer>

  <script>
    fetch('/fetch_rss')
      .then(res => res.json())
      .then(data => {
        const container = document.getElementById('rss-feed');
        if (data.length === 0) {
          container.innerHTML = '<p>No news available right now.</p>';
        } else {
          container.innerHTML = data.map(item => `
            <div class="rss-entry">
              <strong>${item.title}</strong><br>
              <a href="${item.link}" target="_blank">Read more</a><br>
              <small>${item.published}</small>
            </div>
          `).join('<hr>');
        }
      })
      .catch(() => {
        document.getElementById('rss-feed').innerHTML = '<p>Failed to load news feed.</p>';
      });
  </script>
</body>
</html>
```
