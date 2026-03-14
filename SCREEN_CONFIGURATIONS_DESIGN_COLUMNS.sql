-- Add design/style columns to screen_configurations table
ALTER TABLE screen_configurations ADD COLUMN IF NOT EXISTS background_color TEXT;
ALTER TABLE screen_configurations ADD COLUMN IF NOT EXISTS text_color TEXT;
ALTER TABLE screen_configurations ADD COLUMN IF NOT EXISTS accent_color TEXT;
ALTER TABLE screen_configurations ADD COLUMN IF NOT EXISTS font_size DECIMAL(10,2);
ALTER TABLE screen_configurations ADD COLUMN IF NOT EXISTS font_family TEXT;
ALTER TABLE screen_configurations ADD COLUMN IF NOT EXISTS border_radius DECIMAL(10,2);
ALTER TABLE screen_configurations ADD COLUMN IF NOT EXISTS padding DECIMAL(10,2);
ALTER TABLE screen_configurations ADD COLUMN IF NOT EXISTS use_card_style BOOLEAN DEFAULT true;
ALTER TABLE screen_configurations ADD COLUMN IF NOT EXISTS use_shadow BOOLEAN DEFAULT true;
ALTER TABLE screen_configurations ADD COLUMN IF NOT EXISTS header_background_color TEXT;
ALTER TABLE screen_configurations ADD COLUMN IF NOT EXISTS bottom_nav_color TEXT;
ALTER TABLE screen_configurations ADD COLUMN IF NOT EXISTS icon_size DECIMAL(10,2);
