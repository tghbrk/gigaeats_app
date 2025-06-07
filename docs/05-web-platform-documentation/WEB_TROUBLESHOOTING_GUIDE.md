# GigaEats Web Platform Troubleshooting Guide

## 🚨 **Quick Diagnostics**

### **Step 1: Access Web Connection Test**
```
http://localhost:8080/#/test-web-connection
```
This screen will automatically run comprehensive tests and show results.

### **Step 2: Check Browser Console**
Open Developer Tools (F12) and check for:
- Network errors (CORS, 404, 500)
- JavaScript errors
- Firebase Auth status
- Supabase connection logs

---

## 🔍 **Common Issues & Solutions**

### **1. Data Not Loading on Web**

#### **Symptoms:**
- Empty lists/screens on web platform
- Loading indicators that never complete
- "No data found" messages

#### **Diagnosis:**
```bash
# Check Supabase server status
supabase status

# Check if running on correct URL
# Should show: API URL: http://127.0.0.1:54321
```

#### **Solutions:**
1. **Verify Supabase is running:**
   ```bash
   supabase start
   ```

2. **Check URL configuration:**
   - Ensure `SupabaseConfig.devUrlWeb` uses `127.0.0.1:54321`
   - Not `localhost:54321` (can cause CORS issues)

3. **Test authentication:**
   - Navigate to `/test-web-connection`
   - Check Firebase token verification results

---

### **2. CORS Errors**

#### **Symptoms:**
- Browser console shows CORS policy errors
- Network requests blocked
- "Access-Control-Allow-Origin" errors

#### **Solutions:**
1. **Check Supabase URL:**
   ```dart
   // In lib/core/config/supabase_config.dart
   static const String devUrlWeb = 'http://127.0.0.1:54321';
   ```

2. **Verify Supabase CORS settings:**
   ```bash
   # Check supabase/config.toml
   # Ensure proper CORS configuration
   ```

3. **Clear browser cache:**
   - Hard refresh (Ctrl+Shift+R)
   - Clear site data in Developer Tools

---

### **3. Authentication Issues**

#### **Symptoms:**
- User not logged in on web
- Firebase token errors
- Permission denied errors

#### **Solutions:**
1. **Check Firebase Auth status:**
   ```javascript
   // In browser console
   console.log('Firebase user:', firebase.auth().currentUser);
   ```

2. **Verify token validity:**
   - Use web connection test screen
   - Check token expiration
   - Force token refresh

3. **Check RLS policies:**
   - Ensure Supabase RLS policies accept Firebase JWTs
   - Verify `auth.jwt() ->> 'sub'` pattern usage

---

### **4. Network Request Failures**

#### **Symptoms:**
- 500 Internal Server Error
- Connection timeouts
- Request aborted errors

#### **Solutions:**
1. **Check Supabase logs:**
   ```bash
   supabase logs
   ```

2. **Verify database connection:**
   ```bash
   # Test direct database access
   supabase db reset
   ```

3. **Check network connectivity:**
   - Ping Supabase server
   - Test with curl/Postman

---

## 🛠️ **Debug Tools**

### **1. Web Connection Test Screen**
- **URL**: `http://localhost:8080/#/test-web-connection`
- **Features**: Automated testing of all web platform components
- **Use**: First line of diagnosis for any web issues

### **2. Browser Developer Tools**
- **Network Tab**: Check request/response details
- **Console Tab**: View error messages and logs
- **Application Tab**: Check local storage and cookies

### **3. Supabase Studio**
- **URL**: `http://127.0.0.1:54323`
- **Use**: Direct database inspection and query testing

### **4. Firebase Console**
- **URL**: `https://console.firebase.google.com`
- **Use**: Check authentication status and user management

---

## 📋 **Debugging Checklist**

### **Before Starting:**
- [ ] Supabase server is running (`supabase status`)
- [ ] Firebase project is properly configured
- [ ] User is logged in to Firebase Auth
- [ ] Browser has no cached errors (hard refresh)

### **Data Fetching Issues:**
- [ ] Run web connection test (`/test-web-connection`)
- [ ] Check browser console for errors
- [ ] Verify Supabase URL configuration
- [ ] Test Firebase token validity
- [ ] Check RLS policy permissions

### **Authentication Issues:**
- [ ] Verify Firebase Auth status
- [ ] Check token expiration
- [ ] Test manual token refresh
- [ ] Verify user role and permissions

### **Performance Issues:**
- [ ] Check network request timing
- [ ] Monitor memory usage
- [ ] Test with different browsers
- [ ] Verify caching behavior

---

## 🔧 **Advanced Troubleshooting**

### **1. Manual Token Testing**
```javascript
// In browser console
firebase.auth().currentUser.getIdToken(true).then(token => {
  console.log('Firebase token:', token);
  
  // Test with Supabase
  fetch('http://127.0.0.1:54321/rest/v1/users?select=count', {
    headers: {
      'Authorization': `Bearer ${token}`,
      'apikey': 'your-anon-key'
    }
  }).then(response => {
    console.log('Supabase response:', response.status);
  });
});
```

### **2. Database Query Testing**
```sql
-- In Supabase Studio SQL Editor
-- Test RLS policies
SELECT auth.jwt() ->> 'sub' as firebase_uid;
SELECT * FROM users WHERE firebase_uid = auth.jwt() ->> 'sub';
```

### **3. Network Analysis**
```bash
# Test direct API access
curl -H "Authorization: Bearer YOUR_TOKEN" \
     -H "apikey: YOUR_ANON_KEY" \
     http://127.0.0.1:54321/rest/v1/users?select=count
```

---

## 📞 **Getting Help**

### **1. Check Logs**
- Browser console errors
- Supabase server logs (`supabase logs`)
- Flutter debug output

### **2. Gather Information**
- Browser and version
- Error messages (exact text)
- Steps to reproduce
- Web connection test results

### **3. Common Solutions**
- Restart Supabase server
- Clear browser cache
- Check Firebase Auth status
- Verify configuration files

---

**💡 Tip: Always start with the Web Connection Test screen for quick diagnosis!**
