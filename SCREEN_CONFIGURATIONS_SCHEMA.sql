-- Screen Configurations Table
-- Stores dynamic screen configurations for each role
-- Allows admin to control which screens each role can access

CREATE TABLE IF NOT EXISTS screen_configurations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'doctor', 'driver', 'owner')),
    screen_id VARCHAR(100) NOT NULL,
    screen_name VARCHAR(200) NOT NULL,
    screen_description TEXT,
    is_enabled BOOLEAN DEFAULT true,
    is_visible BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    icon_name VARCHAR(50),
    custom_settings JSONB,
    category VARCHAR(50),
    requires_verification BOOLEAN DEFAULT false,
    permissions TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure unique screen per role
    UNIQUE(role, screen_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_screen_configs_role ON screen_configurations(role);
CREATE INDEX IF NOT EXISTS idx_screen_configs_enabled ON screen_configurations(is_enabled);
CREATE INDEX IF NOT EXISTS idx_screen_configs_visible ON screen_configurations(is_visible);
CREATE INDEX IF NOT EXISTS idx_screen_configs_category ON screen_configurations(category);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_screen_configs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_screen_configs_timestamp ON screen_configurations;
CREATE TRIGGER update_screen_configs_timestamp
    BEFORE UPDATE ON screen_configurations
    FOR EACH ROW
    EXECUTE FUNCTION update_screen_configs_updated_at();

-- Insert default screen configurations for Admin role
INSERT INTO screen_configurations (role, screen_id, screen_name, screen_description, icon_name, category, sort_order)
VALUES 
    ('admin', 'user_management', 'User Management', 'Manage users, roles, and permissions', 'people', 'Management', 1),
    ('admin', 'service_management', 'Service Management', 'Manage clinic services and pricing', 'medical_services', 'Management', 2),
    ('admin', 'reporting', 'Reporting & Analytics', 'View reports and analytics', 'analytics', 'Reports', 3),
    ('admin', 'compliance', 'Compliance Records', 'Manage compliance and verification records', 'verified', 'Management', 4),
    ('admin', 'data_management', 'Data Backup & Restore', 'Backup and restore system data', 'backup', 'System', 5),
    ('admin', 'van_management', 'Van Management', 'Manage clinic vans and assignments', 'directions_car', 'Management', 6),
    ('admin', 'area_management', 'Area Management', 'Manage service areas and coverage', 'location_on', 'Management', 7),
    ('admin', 'system_settings', 'System Settings', 'Configure system-wide settings', 'settings', 'System', 8),
    ('admin', 'audit_logs', 'Audit Logs', 'View system audit logs', 'history', 'System', 9),
    ('admin', 'page_management', 'Page Management', 'Manage CMS pages and content', 'description', 'Management', 10),
    ('admin', 'screen_management', 'Screen Management', 'Configure screens for all roles', 'monitoring', 'System', 11)
ON CONFLICT (role, screen_id) DO NOTHING;

-- Insert default screen configurations for Doctor role
INSERT INTO screen_configurations (role, screen_id, screen_name, screen_description, icon_name, category, sort_order, requires_verification)
VALUES 
    ('doctor', 'appointments', 'Appointments', 'Manage your appointments', 'calendar_today', 'Main', 1, false),
    ('doctor', 'medical_records', 'Medical Records', 'View and manage patient records', 'folder', 'Main', 2, true),
    ('doctor', 'emergency_cases', 'Emergency Cases', 'Handle emergency cases', 'emergency', 'Main', 3, true),
    ('doctor', 'inventory', 'Inventory', 'Manage medical supplies inventory', 'inventory', 'Management', 4, true),
    ('doctor', 'schedule_settings', 'Schedule Settings', 'Configure your availability', 'settings', 'Settings', 5, false),
    ('doctor', 'profile', 'Profile', 'Manage your profile and documents', 'person', 'Profile', 6, false),
    ('doctor', 'van_selection', 'Van Selection', 'Select your assigned van', 'directions_car', 'Main', 7, true)
ON CONFLICT (role, screen_id) DO NOTHING;

-- Insert default screen configurations for Driver role
INSERT INTO screen_configurations (role, screen_id, screen_name, screen_description, icon_name, category, sort_order)
VALUES 
    ('driver', 'van_dashboard', 'Van Dashboard', 'Your van operations dashboard', 'directions_car', 'Main', 1),
    ('driver', 'doctor_selection', 'Doctor Selection', 'View assigned doctors', 'people', 'Main', 2),
    ('driver', 'emergency_response', 'Emergency Response', 'Emergency case coordination', 'emergency', 'Main', 3),
    ('driver', 'route_planning', 'Route Planning', 'Plan your daily routes', 'map', 'Main', 4),
    ('driver', 'van_selection', 'Van Selection', 'Select your assigned van', 'local_hospital', 'Main', 5),
    ('driver', 'profile', 'Profile', 'Manage your profile', 'person', 'Profile', 6)
ON CONFLICT (role, screen_id) DO NOTHING;

-- Insert default screen configurations for Owner role
INSERT INTO screen_configurations (role, screen_id, screen_name, screen_description, icon_name, category, sort_order)
VALUES 
    ('owner', 'my_pets', 'My Pets', 'Manage your pets', 'pets', 'Main', 1),
    ('owner', 'book_appointment', 'Book Appointment', 'Book a new appointment', 'calendar_today', 'Main', 2),
    ('owner', 'my_appointments', 'My Appointments', 'View your appointments', 'assignment', 'Main', 3),
    ('owner', 'medical_history', 'Medical History', 'View pet medical history', 'medical_services', 'Main', 4),
    ('owner', 'medical_documents', 'Medical Documents', 'Access pet documents', 'folder', 'Main', 5),
    ('owner', 'driver_tracking', 'Driver Tracking', 'Track your appointment driver', 'map', 'Main', 6),
    ('owner', 'payment_history', 'Payment History', 'View payment records', 'payment', 'Main', 7),
    ('owner', 'profile', 'Profile', 'Manage your profile', 'person', 'Profile', 8)
ON CONFLICT (role, screen_id) DO NOTHING;

-- Row Level Security (RLS) policies for screen_configurations
-- Only admins can manage screen configurations

-- Enable RLS
ALTER TABLE screen_configurations ENABLE ROW LEVEL SECURITY;

-- Policy: Allow all users to read screen configurations
DROP POLICY IF EXISTS screen_configs_read_policy ON screen_configurations;
CREATE POLICY screen_configs_read_policy ON screen_configurations
    FOR SELECT
    USING (true);

-- Policy: Only admins can insert/update/delete
DROP POLICY IF EXISTS screen_configs_admin_policy ON screen_configurations;
CREATE POLICY screen_configs_admin_policy ON screen_configurations
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Grant necessary permissions
GRANT SELECT ON screen_configurations TO authenticated;
GRANT ALL ON screen_configurations TO service_role;
