# Nexoplus Website

Official website for Nexoplus - Your trusted partner in entrance automation and security solutions.

## Features

- Modern, responsive design
- Entrance automation solutions
- Visitor management systems
- Biometric security solutions
- Mobile app integration
- 24/7 support system

## Tech Stack

- HTML5
- CSS3
- JavaScript
- Bootstrap 5
- PHP (for forms)
- Nginx (recommended web server)

## Prerequisites

- Web server (Nginx recommended)
- SSL certificate
- PHP 7.4 or higher
- Git

## Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/nexoplus-website.git
   cd nexoplus-website
   ```

2. Configure web server:
   - Point your domain to the server
   - Configure DNS settings for nexoplus.in
   - Ensure ports 80 and 443 are open

3. Run deployment script:
   ```bash
   chmod +x deploy.sh
   sudo ./deploy.sh
   ```

## Manual Deployment

1. Update system packages:
   ```bash
   sudo apt update
   sudo apt upgrade -y
   ```

2. Install required packages:
   ```bash
   sudo apt install -y nginx certbot python3-certbot-nginx
   ```

3. Configure Nginx:
   - Create site configuration in `/etc/nginx/sites-available/`
   - Enable the site
   - Obtain SSL certificate

4. Set up SSL certificate:
   ```bash
   sudo certbot --nginx -d nexoplus.in -d www.nexoplus.in
   ```

## Directory Structure

```
├── assets/
│   ├── css/
│   ├── img/
│   ├── js/
│   └── vendor/
├── forms/
├── index.html
├── deploy.sh
└── README.md
```

## Form Configuration

1. Update email settings in `forms/contact.php`
2. Configure SMTP settings if required
3. Test form submission

## SSL Certificate Renewal

SSL certificates are automatically renewed through a cron job. Manual renewal:
```bash
sudo certbot renew --force-renewal
```

## Maintenance

- Regular backups recommended
- Monitor SSL certificate expiry
- Keep system packages updated
- Check Nginx logs for issues

## Support

For technical support or queries:
- Email: info@nexoplus.com
- Location: 37/1, KG Nagar, Kamarajar Road, Uppilipalayam Post, Varadharajapuram, Tamil Nadu 641015

## License

All rights reserved. This project and its contents are proprietary to Nexoplus. 