-- Directive 14: Fix Plain Text PINs
-- Run this in Supabase SQL Editor

-- Problem: Your database contains plain text PINs ("1234", "2222"), 
-- but the application sends encrypted SHA-256 hashes. They don't match.

-- Solution: Update the database with the correct hashes.

-- 1. Fix PIN "1234" -> "03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4"
UPDATE employees 
SET pin_hash = '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4'
WHERE pin_hash = '1234';

-- 2. Fix PIN "2222" -> "edee29f882543b956620b26d0ee0e7e950399b1c4222f5de05e06425b4c995e9"
UPDATE employees 
SET pin_hash = 'edee29f882543b956620b26d0ee0e7e950399b1c4222f5de05e06425b4c995e9'
WHERE pin_hash = '2222';

-- Verification
-- SELECT full_name, pin_hash FROM employees;
